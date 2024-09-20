library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg.all;

entity ethernet_rx is
    generic(PAYLOAD_WIDTH: integer := 368);
    port(clk       : in std_logic;
         rst_n     : in std_logic;
         rx_valid  : in std_logic;
         rx_data   : in std_logic_vector(7 downto 0);
         rx_done   : out std_logic;
         crc_calc  : out std_logic := 'X';
         dest_mac  : out std_logic_vector(47 downto 0);
         source_mac: out std_logic_vector(47 downto 0);
         ethertype : out std_logic_vector(15 downto 0);
         payload   : out std_logic_vector(PAYLOAD_WIDTH - 1 downto 0);
         crc_valid : out std_logic);
end ethernet_rx;

architecture ethernet_rx_rtl of ethernet_rx is
    constant FRAME_WIDTH: integer := PAYLOAD_WIDTH + 16 + 48 + 48; -- Payload + ethertype + source + dest width
    type preamble_array is array (0 to 6) of std_logic_vector(7 downto 0);
    type frame_data_array is array (0 to (FRAME_WIDTH / 8) - 1) of std_logic_vector(7 downto 0);
    type crc_array is array (0 to 3) of std_logic_vector(7 downto 0);
    type fsm is (ST_IDLE, ST_PREAMBLE, ST_ADDR, ST_PAYLOAD, 
                 ST_CRC_CALC, ST_CRC_VALIDATE, ST_DONE);
    signal state: fsm;
    signal next_state: fsm; 
    signal preamble_reg: preamble_array;
    signal preamble_next: preamble_array;
    signal sfd: std_logic_vector(7 downto 0);
    signal crc_in_next: crc_array;
    signal crc_in_reg: crc_array;
    signal crc_next: std_logic_vector(31 downto 0) := (others => '1');
    signal crc_reg: std_logic_vector(31 downto 0) := (others => '1');
    signal crc_valid_reg: std_logic;
    signal crc_valid_next: std_logic;
    signal cnt_next: integer range 0 to FRAME_WIDTH / 8 - 1 := 0;
    signal cnt_reg: integer range 0 to FRAME_WIDTH / 8 - 1 := 0;
    signal rx_done_reg: std_logic;
    signal rx_done_next: std_logic;
    signal rx_data_reg: std_logic_vector(7 downto 0);
    signal rx_data_next: std_logic_vector(7 downto 0);
    signal rx_frame_data_reg: frame_data_array;
    signal rx_frame_data_next: frame_data_array;
begin
    state_register: process(clk,rst_n)
    begin
        if rst_n = '0' then
            state <= ST_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
       end if; 
    end process;
    
    next_state_logic: process(state,rx_valid,cnt_reg)
    begin
        next_state <= state;
        case state is
            when ST_IDLE =>
                if rx_valid = '1' then
                    next_state <= ST_PREAMBLE;
                end if;
            when ST_PREAMBLE =>
                if cnt_reg = 7 then
                    next_state <= ST_ADDR;
                end if;
            when ST_ADDR =>
                if cnt_reg = 13 then
                    next_state <= ST_PAYLOAD;
                end if; 
            when ST_PAYLOAD =>
                if cnt_reg = (FRAME_WIDTH / 8) - 1 then
                    next_state <= ST_CRC_CALC;
                end if;
            when ST_CRC_CALC =>
                if cnt_reg = (FRAME_WIDTH / 8) then
                    next_state <= ST_CRC_VALIDATE;
                end if;
            when ST_CRC_VALIDATE =>
                if cnt_reg = 4 then
                    next_state <= ST_DONE;
                end if;
            when ST_DONE =>
                next_state <= ST_IDLE;
        end case;
    end process;

    moore_outputs: rx_done_next <= '1' when state = ST_DONE else '0';
                   crc_calc <= '1' when next_state = ST_CRC_VALIDATE else '0';
    
    mealy_outputs: process(state,rx_data_reg,cnt_reg)
    begin
        cnt_next <= cnt_reg;
        crc_next <= crc_reg;
        crc_in_next <= crc_in_reg;
        preamble_next <= preamble_reg;
        crc_valid_next <= crc_valid_reg;
        rx_frame_data_next <= rx_frame_data_reg;
        case state is
            when ST_IDLE =>
                crc_valid_next <= '0';
            when ST_PREAMBLE =>
                if cnt_reg < 7 then
                    preamble_next(cnt_reg) <= rx_data_reg;
                    cnt_next <= cnt_reg + 1;
                else
                    sfd <= rx_data_reg;
                    cnt_next <= 0;
                end if;
            when ST_ADDR =>
                rx_frame_data_next(cnt_reg) <= rx_data_reg;
                cnt_next <= cnt_reg + 1;   
            when ST_PAYLOAD =>
                rx_frame_data_next(cnt_reg) <= rx_data_reg;
                cnt_next <= cnt_reg + 1;
                if cnt_reg = (FRAME_WIDTH / 8) - 1 then
                    cnt_next <= 0;
                end if;
            when ST_CRC_CALC =>
                if cnt_reg < (FRAME_WIDTH / 8) then
                    crc_next <= crc32(rx_frame_data_reg(cnt_reg),crc_reg);
                    cnt_next <= cnt_reg + 1;
                else
                    crc_next <= not crc_reg;
                    cnt_next <= 0;    
                end if;
            when ST_CRC_VALIDATE =>
                if cnt_reg < 4 then
                    crc_in_next(cnt_reg) <= rx_data_reg;
                    cnt_next <= cnt_reg + 1;
                else    
                    cnt_next <= 0;
                    if crc_reg = crc_in_reg(0) & crc_in_reg(1) & crc_in_reg(2) & crc_in_reg(3) then
                        crc_valid_next <= '1';
                    else
                        crc_valid_next <= '0';
                    end if;
                end if;
            when ST_DONE =>
        end case;
    end process;
    
    -- Buffers
    rx_done <= rx_done_reg;
    rx_data_next <= rx_data;
    crc_valid <= crc_valid_reg;
    
    registers: process(clk,rst_n)
    begin
        if rst_n = '0' then
            cnt_reg <= 0;
            crc_reg <= (others => '1');
            crc_valid_reg <= '0';
            crc_in_reg <= (others => (others => '0'));
            preamble_reg <= (others => (others => '0'));
            rx_frame_data_reg <= (others => (others => '0'));
            rx_done_reg <= '0';
            rx_data_reg <= (others => '0');
        elsif rising_edge(clk) then
            cnt_reg <= cnt_next;
            crc_reg <= crc_next;
            crc_in_reg <= crc_in_next;
            preamble_reg <= preamble_next;
            crc_valid_reg <= crc_valid_next;
            rx_frame_data_reg <= rx_frame_data_next;
            rx_done_reg <= rx_done_next;
            rx_data_reg <= rx_data_next;
        end if;
    end process;
end ethernet_rx_rtl;