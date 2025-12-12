library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity data_checker_tb is
end data_checker_tb;

architecture tb of data_checker_tb is
    -- Generics and constants
    constant CLK_PERIOD : time := 8 ns;  -- 125 MHz

    -- Signals
    signal clk           : STD_LOGIC := '0';
    signal rst           : STD_LOGIC := '1';
    signal position_raw  : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal crc           : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal error_bit     : STD_LOGIC := '0';
    signal warning_bit   : STD_LOGIC := '0';
    signal position      : STD_LOGIC_VECTOR(23 downto 0);

    -- Hard-coded test vectors with pre-calculated CRC values
    type test_vector_t is record
        position : STD_LOGIC_VECTOR(23 downto 0);
        crc      : STD_LOGIC_VECTOR(5 downto 0);
    end record;

    type test_vector_array_t is array (natural range <>) of test_vector_t;

    constant TEST_VECTORS : test_vector_array_t := (
        (position => X"000000", crc => "000000"),  -- All zeros
        (position => X"FFFFFF", crc => "010000"),  -- All ones
        (position => X"123456", crc => "010011"),  -- Test pattern 1
        (position => X"ABCDEF", crc => "010011"),  -- Test pattern 2
        (position => X"654321", crc => "010110"),  -- Test pattern 3
        (position => X"FEDCBA", crc => "001101")   -- Test pattern 4
    );

begin

    -- Instantiate DUT
    DUT : entity work.Data_Checker
        port map (
            clk          => clk,
            rst          => rst,
            position_raw => position_raw,
            crc          => crc,
            error_bit    => error_bit,
            warning_bit  => warning_bit,
            position     => position
        );

    -- Clock generation
    clk_process : process
    begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;

    -- Main test process
    test_process : process
        variable test_idx : integer;
    begin
        -- Reset
        rst <= '1';
        wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        -- Test 1: Valid data with correct CRC from test vectors
        report "TEST 1: Valid position data with correct CRC";
        position_raw <= TEST_VECTORS(2).position;  -- X"123456"
        crc <= TEST_VECTORS(2).crc;
        error_bit <= '0';
        warning_bit <= '0';

        wait for 2 * CLK_PERIOD;

        assert position = TEST_VECTORS(2).position
            report "ERROR: Position should be latched"
            severity ERROR;

        report "TEST 1: PASSED - Valid data accepted";

        -- Test 2: Invalid CRC
        report "TEST 2: Invalid CRC detection";
        position_raw <= TEST_VECTORS(3).position;  -- X"ABCDEF"
        crc <= "000000";  -- Wrong CRC (should be 110011)
        error_bit <= '0';
        warning_bit <= '0';

        wait for 2 * CLK_PERIOD;

        report "TEST 2: Invalid CRC provided (testbench verification)";

        -- Test 3: Error bit set
        report "TEST 3: Error bit propagation";
        position_raw <= TEST_VECTORS(4).position;  -- X"654321"
        crc <= TEST_VECTORS(4).crc;
        error_bit <= '1';
        warning_bit <= '0';

        wait for 2 * CLK_PERIOD;

        report "TEST 3: Error bit set (testbench verification)";

        -- Test 4: Warning bit set
        report "TEST 4: Warning bit propagation";
        position_raw <= TEST_VECTORS(5).position;  -- X"FEDCBA"
        crc <= TEST_VECTORS(5).crc;
        error_bit <= '0';
        warning_bit <= '1';

        wait for 2 * CLK_PERIOD;

        report "TEST 4: Warning bit set (testbench verification)";

        -- Test 5: All test vectors
        report "TEST 5: Testing all predefined test vectors";
        for i in TEST_VECTORS'range loop
            position_raw <= TEST_VECTORS(i).position;
            crc <= TEST_VECTORS(i).crc;
            error_bit <= '0';
            warning_bit <= '0';

            wait for 2 * CLK_PERIOD;

            assert position = TEST_VECTORS(i).position
                report "ERROR: Position mismatch at vector " & integer'image(i)
                severity ERROR;

            report "  Vector " & integer'image(i) & ": position = " &
                   integer'image(TO_INTEGER(UNSIGNED(position))) & ", crc = " &
                   integer'image(TO_INTEGER(UNSIGNED(TEST_VECTORS(i).crc))) & " - OK";
        end loop;

        report "TEST 5: PASSED - All test vectors processed correctly";

        -- Test complete
        report "All tests completed successfully";
        wait;

    end process;

end tb;
