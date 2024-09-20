library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_rx_tb is
--  Port ( );
end ethernet_rx_tb;

architecture ethernet_rx_behav of ethernet_rx_tb is
    constant CLK_PERIOD: time := 20 ns;
    constant PAYLOAD_WIDTH: integer := 512;
    -- Testbench Signals
    signal clk       : std_logic := '0';
    signal rst_n     : std_logic := '0';
    signal rx_valid  : std_logic := '0';
    signal rx_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_done   : std_logic;
    signal crc_calc  : std_logic;
    signal dest_mac  : std_logic_vector(47 downto 0);
    signal source_mac: std_logic_vector(47 downto 0);
    signal ethertype : std_logic_vector(15 downto 0);
    signal payload   : std_logic_vector(PAYLOAD_WIDTH - 1 downto 0);
    signal crc_valid : std_logic;
    signal end_test  : std_logic := '0';
begin
    uut: entity work.ethernet_rx(ethernet_rx_rtl)
    generic map(PAYLOAD_WIDTH => PAYLOAD_WIDTH)
    port map(clk => clk, rst_n => rst_n, rx_valid => rx_valid,
             rx_data => rx_data, rx_done => rx_done, dest_mac => dest_mac,
             source_mac => source_mac, ethertype => ethertype, payload => payload,
             crc_valid => crc_valid, crc_calc => crc_calc);
    
    reset: rst_n <= '0', '1' after CLK_PERIOD;
    
    clock_generation: process
    begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;
 
    stim_proc: process
    begin
        -- Start sending data (simulate RX data)
        wait until rst_n = '1';
        
        wait until rising_edge(clk);
        rx_valid <= '1';
        -- Preamble (7 bytes of x"55")
        for i in 0 to 6 loop
        rx_data <= x"55";
        wait for CLK_PERIOD;
        end loop;
        
        -- Start Frame Delimiter (SFD)
        rx_data <= x"AB";
        wait for CLK_PERIOD;
        
        -- Destination MAC Address (example: x"112233445566")
        rx_data <= x"FF";
        wait for CLK_PERIOD;
        rx_data <= x"FF";
        wait for CLK_PERIOD;
        rx_data <= x"FF";
        wait for CLK_PERIOD;
        rx_data <= x"FF";
        wait for CLK_PERIOD;
        rx_data <= x"FF";
        wait for CLK_PERIOD;
        rx_data <= x"FF";
        wait for CLK_PERIOD;
        
        -- Source MAC Address (example: x"AABBCCDDEEFF")
        rx_data <= x"00";
        wait for CLK_PERIOD;
        rx_data <= x"1A";
        wait for CLK_PERIOD;
        rx_data <= x"2B";
        wait for CLK_PERIOD;
        rx_data <= x"3C";
        wait for CLK_PERIOD;
        rx_data <= x"4D";
        wait for CLK_PERIOD;
        rx_data <= x"5E";
        wait for CLK_PERIOD;
        
        -- Ethertype (example: x"0800" for IPv4)
        rx_data <= x"08";
        wait for CLK_PERIOD;
        rx_data <= x"00";
        wait for CLK_PERIOD;
        
        -- Payload (alternating bytes of x"FF" and x"00")
        for i in 0 to 63 loop
            if (i / 8) mod 2 = 0 then -- Even rows
                if i mod 2 = 0 then
                    rx_data <= x"FF"; -- Even columns in even rows
                else
                    rx_data <= x"00"; -- Odd columns in even rows
                end if;
            else -- Odd rows
                if i mod 2 = 0 then
                    rx_data <= x"00"; -- Even columns in odd rows
                else
                    rx_data <= x"FF"; -- Odd columns in odd rows
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;
        
        wait until crc_calc = '1';
        rx_data <= x"F2";
        wait for CLK_PERIOD;
        rx_data <= x"31";
        wait for CLK_PERIOD;
        rx_data <= x"4D";
        wait for CLK_PERIOD;
        rx_data <= x"EC";
        wait for CLK_PERIOD;
        
        -- End of data
        wait until rx_done = '1';
        rx_valid <= '0';        
        wait for CLK_PERIOD;
        end_test <= '1';
    end process;
    
    output_report: process
    begin 
        wait until rst_n = '1';
        wait until rx_done = '1';
        report "Done Receiving";
        
        wait until end_test = '1';
        assert false report "Simulation done" severity failure;
        wait;
    end process;
end ethernet_rx_behav;
