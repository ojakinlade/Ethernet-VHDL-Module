library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg.all;

entity ethernet_tx is
  generic(PAYLOAD_WIDTH: integer := 368);
  port (clk       : in std_logic;
        rst_n     : in std_logic;
        start_tx  : in std_logic;
        dest_mac  : in std_logic_vector(47 downto 0);
        source_mac: in std_logic_vector(47 downto 0);
        ethertype : in std_logic_vector(15 downto 0);
        tx_data   : out std_logic_vector(7 downto 0);
        tx_done   : out std_logic;
        bram_addr : out std_logic_vector(7 downto 0); 
        bram_dout : in std_logic_vector(7 downto 0);  
        bram_en   : out std_logic);                     
end ethernet_tx;

architecture ethernet_tx_rtl of ethernet_tx is
    constant FRAME_WIDTH: integer := PAYLOAD_WIDTH + 16 + 48 + 48; -- Payload + ethertype + source + dest width
    constant PREAMBLE: std_logic_vector(7 downto 0) := x"55";
    constant SFD: std_logic_vector(7 downto 0) := x"AB"; -- Start Frame Delimiter
    type fsm is (ST_IDLE, ST_PREAMBLE, ST_ADDR, ST_BRAM_READ, ST_BRAM_SETUP, ST_BRAM_RDY, 
                 ST_GET_PAYLOAD, ST_DATA_TX ,ST_CRC_CALC, ST_CRC_TX, ST_DONE);
    signal state: fsm;
    signal next_state: fsm;
    signal crc_next: std_logic_vector(31 downto 0);
    signal crc_reg: std_logic_vector(31 downto 0);
    signal cnt_next: integer range 0 to FRAME_WIDTH / 8 - 1;
    signal cnt_reg: integer range 0 to FRAME_WIDTH / 8 - 1;
    signal tx_done_reg: std_logic;
    signal tx_done_next: std_logic;
    signal tx_data_reg: std_logic_vector(7 downto 0);
    signal tx_data_next: std_logic_vector(7 downto 0);
    signal bram_en_reg: std_logic;
    signal bram_en_next: std_logic;
    signal bram_dout_reg: std_logic_vector(7 downto 0);
    signal bram_dout_next: std_logic_vector(7 downto 0);
    signal bram_addr_reg: std_logic_vector(7 downto 0);
    signal bram_addr_next: std_logic_vector(7 downto 0);
    signal frame_data_reg: std_logic_vector(FRAME_WIDTH - 1 downto 0);
    signal frame_data_next: std_logic_vector(FRAME_WIDTH - 1 downto 0);
    signal data_in_reg: std_logic_vector(PAYLOAD_WIDTH - 1 downto 0);
    signal data_in_next: std_logic_vector(PAYLOAD_WIDTH - 1 downto 0);
begin
    state_register: process(clk,rst_n)
    begin
        if rst_n = '0' then
            state <= ST_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
       end if; 
    end process;
    
    next_state_logic: process(state,start_tx,cnt_reg)
    begin
        next_state <= state;
        case state is
            when ST_IDLE =>
                if start_tx = '1' then
                    next_state <= ST_PREAMBLE;
                end if;
            when ST_PREAMBLE =>
                if cnt_reg = 7 then
                    next_state <= ST_ADDR;
                end if;
            when ST_ADDR =>
                if cnt_reg = 13 then
                    next_state <= ST_BRAM_READ;
                end if;
            when ST_BRAM_READ =>
                next_state <= ST_BRAM_SETUP;
            when ST_BRAM_SETUP =>
                next_state <= ST_BRAM_RDY;
            when ST_BRAM_RDY =>
                next_state <= ST_GET_PAYLOAD;
            when ST_GET_PAYLOAD =>
                if cnt_reg = (PAYLOAD_WIDTH / 8) then
                    next_state <= ST_DATA_TX;
                else 
                    next_state <= ST_BRAM_READ;
                end if;
            when ST_DATA_TX =>
                if cnt_reg = (PAYLOAD_WIDTH / 8) then
                    next_state <= ST_CRC_CALC;
                end if;
            when ST_CRC_CALC =>
                if cnt_reg = (FRAME_WIDTH / 8) then
                    next_state <= ST_CRC_TX;
                end if;
            when ST_CRC_TX =>
                if cnt_reg = 4 then 
                    next_state <= ST_DONE;
                end if;
            when ST_DONE => 
                next_state <= ST_IDLE;
        end case;
    end process;
    
    moore_outputs: tx_done_next <= '1' when state = ST_DONE else '0';
    
    mealy_outputs: process(state,cnt_reg,tx_data_reg,dest_mac,source_mac,ethertype,crc_reg,frame_data_reg,bram_dout_reg,data_in_reg)
    begin
        tx_data_next <= tx_data_reg;
        cnt_next <= cnt_reg;
        crc_next <= crc_reg;
        data_in_next <= data_in_reg;
        frame_data_next <= frame_data_reg;
        bram_en_next <= bram_en_reg;
        bram_addr_next <= bram_addr_reg;
        case state is
            when ST_IDLE => 
            when ST_PREAMBLE => 
                if cnt_reg < 7 then
                    tx_data_next <= PREAMBLE;
                    cnt_next <= cnt_reg + 1;
                else
                    tx_data_next <= SFD;
                    cnt_next <= 0;                   
                end if;
            when ST_ADDR => 
                case cnt_reg is
                    when 0 to 5 => tx_data_next <= dest_mac(47 - (cnt_reg * 8) downto 40 - (cnt_reg * 8));
                    when 6 to 11 => tx_data_next <= source_mac(47 - ((cnt_reg - 6) * 8) downto 40 - ((cnt_reg - 6) * 8));
                    when 12 to 13 => tx_data_next <= ethertype(15 - ((cnt_reg - 12) * 8) downto 8 - ((cnt_reg - 12) * 8));
                    when others =>
                end case;
                if cnt_reg = 13 then
                    cnt_next <= 0;
                else
                    cnt_next <= cnt_reg + 1;
                end if;
            when ST_BRAM_READ =>
                bram_en_next <= '1';
                if cnt_reg /= (PAYLOAD_WIDTH / 8) then
                    bram_addr_next <= std_logic_vector(to_unsigned(cnt_reg, bram_addr'length)); 
                end if;
            when ST_BRAM_SETUP =>
            when ST_BRAM_RDY =>
            when ST_GET_PAYLOAD =>
                if cnt_reg = (PAYLOAD_WIDTH / 8) then
                    frame_data_next <= dest_mac & source_mac & ethertype & data_in_reg;
                    bram_en_next <= '0';
                    cnt_next <= 0;
                else
                    -- Accumulate the read bytes into `data_in`
                    data_in_next((PAYLOAD_WIDTH - 1) - (cnt_reg * 8) downto (PAYLOAD_WIDTH - 8) - (cnt_reg * 8)) <= bram_dout_reg;
                    cnt_next <= cnt_reg + 1;
                end if;
            when ST_DATA_TX =>
                if cnt_reg < (PAYLOAD_WIDTH / 8) then
                    tx_data_next <= data_in_reg((PAYLOAD_WIDTH - 1) - (cnt_reg * 8) downto (PAYLOAD_WIDTH - 8) - (cnt_reg * 8));
                    cnt_next <= cnt_reg + 1;     
                else
                    cnt_next <= 0;
                end if;
            when ST_CRC_CALC =>
                if cnt_reg < (FRAME_WIDTH / 8) then
                    crc_next <= crc32(frame_data_reg((FRAME_WIDTH - 1) - (cnt_reg * 8) downto (FRAME_WIDTH - 8) - (cnt_reg * 8)), crc_reg);
                    cnt_next <= cnt_reg + 1;
                else
                    crc_next <= not crc_reg;
                    cnt_next <= 0;
                end if;   
            when ST_CRC_TX => 
                if cnt_reg < 4 then
                    tx_data_next <= crc_reg(31 - (cnt_reg * 8) downto 24 - (cnt_reg * 8));
                    cnt_next <= cnt_reg + 1;
                else
                    cnt_next <= 0;
                end if;
            when ST_DONE =>     
        end case;
    end process;
    
    -- Buffers
    bram_dout_next <= bram_dout;
    tx_data <= tx_data_reg;
    tx_done <= tx_done_reg;
    bram_addr <= bram_addr_reg;
    bram_en <= bram_en_reg;
    
    registers: process(clk,rst_n)
    begin
        if rst_n = '0' then
            cnt_reg <= 0;
            crc_reg <= (others => '1');
            tx_done_reg <= '0';
            tx_data_reg <= (others => '0');
            bram_en_reg <= '0';
            bram_dout_reg <= (others => '0');
            bram_addr_reg <= (others => '0');
            data_in_reg <= (others => '0');
            frame_data_reg <= (others => '0');
        elsif rising_edge(clk) then
            cnt_reg <= cnt_next;
            crc_reg <= crc_next;
            tx_done_reg <= tx_done_next;
            tx_data_reg <= tx_data_next;
            bram_dout_reg <= bram_dout_next;
            bram_en_reg <= bram_en_next;
            bram_addr_reg <= bram_addr_next;
            data_in_reg <= data_in_next;
            frame_data_reg <= frame_data_next;
        end if;
    end process;
end ethernet_tx_rtl;