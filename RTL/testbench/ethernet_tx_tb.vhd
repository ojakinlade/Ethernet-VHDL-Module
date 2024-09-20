library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_tx_tb is
--  Port ( );
end ethernet_tx_tb;

architecture ethernet_tx_behav of ethernet_tx_tb is
    constant PAYLOAD_WIDTH: integer := 512;
    constant CLK_PERIOD: time := 20ns;
    constant SOURCE_MAC: std_logic_vector(47 downto 0) := x"001A2B3C4D5E";
    constant DEST_MAC: std_logic_vector(47 downto 0) := x"FFFFFFFFFFFF";
    constant ETHER_TYPE: std_logic_vector(15 downto 0) := x"0800"; -- IPv4
    signal clk: std_logic := '0';
    signal rst_n: std_logic;
    signal start_tx: std_logic := '0';
    signal tx_data: std_logic_vector(7 downto 0);
    signal tx_done: std_logic;
    signal bram_addr: std_logic_vector(7 downto 0);
    signal bram_dout: std_logic_vector(7 downto 0) := (others => '0');
    signal bram_en: std_logic := '0';
    signal end_test: std_logic := '0';
    
     -- Data for the payload (emulating the BRAM content)
    type bram_type is array (0 to 63) of std_logic_vector(7 downto 0);
    signal bram: bram_type := (
        x"FF", x"00", x"FF", x"00", x"FF", x"00", x"FF", x"00", 
        x"00", x"FF", X"00", X"FF", X"00", X"FF", X"00", X"FF",
        x"FF", x"00", x"FF", x"00", x"FF", x"00", x"FF", x"00", 
        x"00", x"FF", X"00", X"FF", X"00", X"FF", X"00", X"FF", 
        x"FF", x"00", x"FF", x"00", x"FF", x"00", x"FF", x"00", 
        x"00", x"FF", X"00", X"FF", X"00", X"FF", X"00", X"FF",
        x"FF", x"00", x"FF", x"00", x"FF", x"00", x"FF", x"00", 
        x"00", x"FF", X"00", X"FF", X"00", X"FF", X"00", X"FF"
    );
begin
    uut: entity work.ethernet_tx(ethernet_tx_rtl)
    generic map(PAYLOAD_WIDTH => PAYLOAD_WIDTH)
    port map(clk => clk, rst_n => rst_n,
             start_tx => start_tx, dest_mac => DEST_MAC,
             source_mac => SOURCE_MAC, ethertype => ETHER_TYPE,
             tx_data => tx_data, tx_done => tx_done, bram_addr => bram_addr,
             bram_dout => bram_dout, bram_en => bram_en);
    
    reset: rst_n <= '0', '1' after CLK_PERIOD;
    
    clock_generation: process
    begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;
    
    bram_process: process(clk)
    begin
        if rising_edge(clk) then
            if bram_en = '1' then
                bram_dout <= bram(to_integer(unsigned(bram_addr)));
            else
                bram_dout <= (others => '0');
            end if;
        end if;
    end process;
    
    stimuli: process
    begin
        wait until rst_n = '1';
        wait until rising_edge(clk);
        -- Start tansmitter
        start_tx <= '1';
        wait until tx_done = '1';
        -- Stop transmitter
        start_tx <= '0';
        wait for CLK_PERIOD;
        end_test <= '1';
        wait;
    end process;
    
    output_report: process
    begin 
        wait until rst_n = '1';
        wait until tx_done = '1';
        report "Done Transmitting";
        
        wait until end_test = '1';
        assert false report "Simulation done" severity failure;
        wait;
    end process;
end ethernet_tx_behav;