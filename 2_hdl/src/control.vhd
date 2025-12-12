library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Control is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        request_frame : out STD_LOGIC
    );
end Control;

architecture Behavioral of Control is
begin
    -- Implementation placeholder
    request_frame <= '0';
end Behavioral;
