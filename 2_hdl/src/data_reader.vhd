library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Data_Reader is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        request_frame : in  STD_LOGIC;
        biss_slo      : in  STD_LOGIC;
        biss_ma       : out STD_LOGIC;
        position_raw  : out STD_LOGIC_VECTOR (23 downto 0);
        crc           : out STD_LOGIC_VECTOR (5 downto 0);
        error_bit     : out STD_LOGIC;
        warning_bit   : out STD_LOGIC
    );
end Data_Reader;

architecture Behavioral of Data_Reader is
begin
    -- Implementation placeholder
    biss_ma <= '0';
    position_raw <= (others => '0');
    crc <= (others => '0');
    error_bit <= '0';
    warning_bit <= '0';
end Behavioral;
