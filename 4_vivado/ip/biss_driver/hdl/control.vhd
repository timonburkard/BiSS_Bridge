library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.biss_bridge_pkg.all;

entity Control is
    generic (
        SAMPLE_FREQ_HZ : positive := 10_000;       -- desired pulse frequency
        CLK_FREQ_HZ    : positive := 50_000_000     -- core clock frequency
    );
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        request_frame : out STD_LOGIC
    );
end Control;

architecture Behavioral of Control is
    -- Number of input clocks per pulse period
    constant DIVIDER : integer := integer(CLK_FREQ_HZ / SAMPLE_FREQ_HZ);
    -- Counter sized by DIVIDER (generic constant used in range)
    signal counter : integer range 0 to DIVIDER := 0;
begin

    -- Single-cycle pulse generator at SAMPLE_FREQ_HZ
    process(clk, rst)
    begin
        if rising_edge(clk) then
            if counter = DIVIDER - 1 then
                counter <= 0;
                request_frame <= '1';
            else
                counter <= counter + 1;
                request_frame <= '0';
            end if;

            -- reset
            if rst = '1' then
                counter <= 0;
                request_frame <= '0';
            end if;
        end if;
    end process;

end Behavioral;
