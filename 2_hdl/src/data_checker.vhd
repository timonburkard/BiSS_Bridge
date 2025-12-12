library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Data_Checker is
    Port (
        clk          : in  STD_LOGIC;
        rst          : in  STD_LOGIC;
        position_raw : in  STD_LOGIC_VECTOR (23 downto 0);
        crc          : in  STD_LOGIC_VECTOR (5 downto 0);
        error_bit    : in  STD_LOGIC;
        warning_bit  : in  STD_LOGIC;
        position     : out STD_LOGIC_VECTOR (23 downto 0)
    );
end Data_Checker;

architecture Behavioral of Data_Checker is
begin
    -- Implementation placeholder
    position <= (others => '0');
end Behavioral;
