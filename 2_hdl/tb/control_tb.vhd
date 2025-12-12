library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.biss_bridge_pkg.all;

entity control_tb is
end control_tb;

architecture tb of control_tb is
    -- Clock and reset
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '1';

    -- Outputs
    signal request_frame : STD_LOGIC;

    -- Test parameters
    constant CLK_PERIOD : time := 1 sec / real(C_CLK_FREQ_HZ);  -- 125 MHz
    constant PULSE_FREQ : positive := 10_000;  -- 10 kHz
    constant EXPECTED_PERIOD : integer := C_CLK_FREQ_HZ / PULSE_FREQ;  -- 12500 cycles

    -- Test signals
    signal pulse_count : integer := 0;
    signal cycle_count : integer := 0;

begin

    -- Instantiate DUT
    DUT : entity work.Control
        generic map (
            PULSE_FREQ_HZ => PULSE_FREQ
        )
        port map (
            clk           => clk,
            rst           => rst,
            request_frame => request_frame
        );

    -- Clock generation
    clk_process : process
    begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;

    -- Main test process
    test_process : process
    begin
        -- Reset
        rst <= '1';
        wait for 10 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        -- Test 1: Check pulse generation over multiple periods
        report "TEST 1: Verifying pulse generation at " & integer'image(PULSE_FREQ) & " Hz";
        pulse_count <= 0;
        cycle_count <= 0;

        for pulse_num in 1 to 5 loop
            wait until rising_edge(clk) and request_frame = '1';
            pulse_count <= pulse_num;

            -- Check pulse duration (should be 1 cycle)
            wait for CLK_PERIOD;
            assert request_frame = '0'
                report "ERROR: Pulse should be single-cycle"
                severity ERROR;

            -- Measure cycles until next pulse
            cycle_count <= 0;
            for i in 1 to EXPECTED_PERIOD loop
                wait for CLK_PERIOD;
                cycle_count <= i;

                if i < EXPECTED_PERIOD - 1 then
                    assert request_frame = '0'
                        report "ERROR: Unexpected pulse at cycle " & integer'image(i)
                        severity ERROR;
                end if;
            end loop;

            if pulse_num < 5 then
                report "Pulse " & integer'image(pulse_num) & " detected at cycle " &
                       integer'image(cycle_count) & " (expected ~" & integer'image(EXPECTED_PERIOD) & ")";
            end if;
        end loop;

        report "TEST 1: PASSED - Generated 5 pulses with correct timing";

        -- Test 2: Reset during operation
        report "TEST 2: Testing reset during operation";
        wait until rising_edge(clk);
        rst <= '1';
        wait for 5 * CLK_PERIOD;

        assert request_frame = '0'
            report "ERROR: request_frame should be '0' during reset"
            severity ERROR;

        rst <= '0';
        wait for CLK_PERIOD;

        report "TEST 2: PASSED - Reset works correctly";

        -- Test complete
        report "All tests completed successfully";
        wait;

    end process;

end tb;
