library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_top is
  generic(PAYLOAD_WIDTH: integer := 368);
  Port (clk     : in std_logic;
        rst_n   : in std_logic;
        start_tx: in std_logic;
--        tx_clk  : in std_logic;
        dest_mac  : out std_logic_vector(47 downto 0);
        source_mac: out std_logic_vector(47 downto 0);
        ethertype : out std_logic_vector(15 downto 0);
        payload   : out std_logic_vector(PAYLOAD_WIDTH - 1 downto 0);
        crc_valid : out std_logic;
        tx_data : out std_logic_vector(7 downto 0);
        tx_done : out std_logic;
        rx_done : out std_logic);
end ethernet_top;

architecture ethernet_top_rtl of ethernet_top is
    constant SOURCE_MAC_ADDR: std_logic_vector(47 downto 0) := x"00B0D063C226";
    constant DEST_MAC_ADDR: std_logic_vector(47 downto 0) := x"0123456789AB";
    constant ETHER_TYPE: std_logic_vector(15 downto 0) := x"0800"; -- IPv4
    signal bram_en: std_logic;
    signal bram_dout : std_logic_vector(7 downto 0);
    signal bram_addr : std_logic_vector(7 downto 0);
    signal tx_data_in: std_logic_vector(7 downto 0);
begin
    BRAM: entity work.bram(bram_rtl)
    port map(clk => clk, en => bram_en, addr => bram_addr, dout => bram_dout);

    ethernet_tx: entity work.ethernet_tx(ethernet_tx_rtl)
    port map(clk => clk, rst_n => rst_n,
             start_tx => start_tx, dest_mac => DEST_MAC_ADDR,
             source_mac => SOURCE_MAC_ADDR, ethertype => ETHER_TYPE,
             tx_data => tx_data_in, tx_done => tx_done, bram_addr => bram_addr,
             bram_dout => bram_dout, bram_en => bram_en); 
    ethernet_rx: entity work.ethernet_rx(ethernet_rx_rtl)
    port map(clk => clk, rst_n => rst_n, rx_valid => start_tx,
             rx_data => tx_data_in, rx_done => rx_done, dest_mac => dest_mac,
             source_mac => source_mac, ethertype => ethertype, payload => payload,
             crc_valid => crc_valid);         
end ethernet_top_rtl;