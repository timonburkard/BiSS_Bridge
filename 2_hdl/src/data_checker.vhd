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
        error_bit    : in  STD_LOGIC;
        warning_bit  : in  STD_LOGIC;
        position     : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
    );
end Data_Checker;

architecture Behavioral of Data_Checker is

    -- CRC-6 polynomial for MU150 / BiSS: x^6 + x + 1 (hex 0x43)
    -- Implemented MSB-first over the 24-bit position word.
    function calculate_crc6(position_data : STD_LOGIC_VECTOR(23 downto 0)) return STD_LOGIC_VECTOR is
        variable crc : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
        variable feedback : STD_LOGIC;
    begin
        -- Process MSB first (23 downto 0)
        for i in position_data'range loop
            -- feedback = input_bit xor crc_msb
            feedback := position_data(i) xor crc(5);
            -- shift left by 1
            crc := crc(4 downto 0) & '0';
            -- XOR with polynomial (without MSB): x^1 + x^0 => bits 1 and 0
            if feedback = '1' then
                crc(1) := not crc(1);
                crc(0) := not crc(0);
            end if;
        end loop;
        return crc;
    end function;

    signal position_latched : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal crc_calculated  : STD_LOGIC_VECTOR(5 downto 0);
    signal crc_valid       : STD_LOGIC;

begin

    crc_calculated <= calculate_crc6(position_raw);
    crc_valid <= '1' when (crc_calculated = crc) else '0';

    process(clk, rst)
    begin
        if rising_edge(clk) then
            -- Only latch position if CRC is valid and no errors
            if crc_valid = '1' and error_bit = '0' then
                position_latched <= position_raw;
            end if;

            -- reset
            if rst = '1' then
                position_latched <= (others => '0');
            end if;
        end if;
    end process;

    -- Output validated position, or keep previous valid value if current data is invalid
    position <= position_latched;

end Behavioral;
