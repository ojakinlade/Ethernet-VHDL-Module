library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bram is
    generic(DATA_WIDTH : integer := 8;        
            ADDR_WIDTH : integer := 8);
    port(clk : in std_logic;            
         en  : in std_logic;             
         addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
         dout: out std_logic_vector(DATA_WIDTH - 1 downto 0));
end bram;

architecture bram_rtl of bram is
    type ram_type is array (2**ADDR_WIDTH - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram : ram_type;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                dout <= ram(to_integer(unsigned(addr)));  -- Output data from the BRAM
            end if;
        end if;
    end process;
end bram_rtl;