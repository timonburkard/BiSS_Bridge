library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Data_Checker is
    Generic (
        DATA_WIDTH : integer := 24;
        CRC_WIDTH  : integer := 6
    );
    Port (
        clk          : in  STD_LOGIC;
        rst          : in  STD_LOGIC;
        position_raw : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        crc          : in  STD_LOGIC_VECTOR (CRC_WIDTH-1 downto 0);
        error_bit    : in  STD_LOGIC;  -- decoded error (active '1')
        warning_bit  : in  STD_LOGIC;  -- decoded warning (active '1')
        data_valid_in: in  STD_LOGIC;
        position     : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        data_valid_out: out STD_LOGIC;
        crc_fail_bit : out STD_LOGIC
    );
end Data_Checker;

architecture Behavioral of Data_Checker is

    -- CRC-6 polynomial for BiSS-C: x^6 + x + 1 (hex 0x43)
    -- CRC covers position bits plus status bits (error, warning) as transmitted on SLO.
    function calculate_crc6(
        position_data : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        error_tx_bit  : STD_LOGIC;  -- raw transmitted bit on SLO (before decoding)
        warn_tx_bit   : STD_LOGIC   -- raw transmitted bit on SLO (before decoding)
    ) return STD_LOGIC_VECTOR is
        variable crc : STD_LOGIC_VECTOR(CRC_WIDTH-1 downto 0) := (others => '0');
        variable feedback : STD_LOGIC;
    begin
        -- Process MSB first (DATA_WIDTH-1 downto 0)
        for i in position_data'range loop
            -- feedback = input_bit xor crc_msb
            feedback := position_data(i) xor crc(CRC_WIDTH-1);
            -- shift left by 1
            crc := crc(CRC_WIDTH-2 downto 0) & '0';
            -- XOR with polynomial (without MSB): x^1 + x^0 => bits 1 and 0
            if feedback = '1' then
                crc(1) := not crc(1);
                crc(0) := not crc(0);
            end if;
        end loop;

        -- Include status bits as transmitted on the line (not decoded/inverted)
        -- Error bit
        feedback := error_tx_bit xor crc(CRC_WIDTH-1);
        crc := crc(CRC_WIDTH-2 downto 0) & '0';
        if feedback = '1' then
            crc(1) := not crc(1);
            crc(0) := not crc(0);
        end if;

        -- Warning bit
        feedback := warn_tx_bit xor crc(CRC_WIDTH-1);
        crc := crc(CRC_WIDTH-2 downto 0) & '0';
        if feedback = '1' then
            crc(1) := not crc(1);
            crc(0) := not crc(0);
        end if;

        return crc;
    end function;

    signal position_latched : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others => '0');
    signal crc_calculated  : STD_LOGIC_VECTOR(CRC_WIDTH-1 downto 0);
    signal crc_valid       : STD_LOGIC;

    attribute mark_debug : string;
    attribute mark_debug of crc_calculated : signal is "true";

begin

    -- Guard against accidental CRC width misconfiguration (BiSS uses CRC-6)
    assert CRC_WIDTH = 6
        report "Data_Checker expects CRC_WIDTH=6 (BiSS CRC-6)"
        severity failure;

    -- Data_Reader provides decoded error/warning (active-high), but BiSS transmits inverted.
    -- Reconstruct raw transmitted bits for CRC: raw = not(decoded)
    crc_calculated <= calculate_crc6(position_raw, not error_bit, not warning_bit);
    -- Many BiSS encoders (e.g., MU150) transmit inverted CRC bits
    crc_valid <= '1' when (crc_calculated = (not crc)) else '0';

    process(clk, rst)
    begin
        if rising_edge(clk) then
            data_valid_out <= '0';

            if data_valid_in = '1' then
                if crc_valid = '1' then
                    crc_fail_bit <= '0';
                else
                    crc_fail_bit <= '1';
                end if;

                position_latched <= position_raw;
                data_valid_out <= '1';
            end if;

            -- reset
            if rst = '1' then
                position_latched <= (others => '0');
                data_valid_out <= '0';
                crc_fail_bit <= '0';
            end if;
        end if;
    end process;

    -- Output validated position, or keep previous valid value if current data is invalid
    position <= position_latched;

end Behavioral;
