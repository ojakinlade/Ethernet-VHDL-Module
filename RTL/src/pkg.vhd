library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package pkg is
    function crc32(
        data_in: std_logic_vector(7 downto 0); 
        crc_in: std_logic_vector(31 downto 0))
    return std_logic_vector;
end package;

package body pkg is
    function crc32(
        data_in: std_logic_vector(7 downto 0); 
        crc_in: std_logic_vector(31 downto 0))
    return std_logic_vector is
        variable crc: std_logic_vector(31 downto 0) := crc_in;
        variable data: std_logic_vector(7 downto 0) := data_in;
        variable tmp: std_logic;  
    begin
        for i in 0 to 7 loop
            tmp := data(0) xor crc(0);
            crc := '0' & crc(31 downto 1) ;
            if tmp = '1' then
                crc := crc xor x"EDB88320";
            end if;
            data := '0' & data(7 downto 1);
        end loop;
        return crc; 
    end crc32;    
end package body pkg;
