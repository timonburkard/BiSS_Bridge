library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Data_Reader is
    Generic (
        DATA_WIDTH : integer := 24;
        CRC_WIDTH  : integer := 6
    );
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        request_frame : in  STD_LOGIC;
        biss_slo      : in  STD_LOGIC;
        biss_ma       : out STD_LOGIC;
        position_raw  : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        crc           : out STD_LOGIC_VECTOR (CRC_WIDTH-1 downto 0);
        error_bit     : out STD_LOGIC;
        warning_bit   : out STD_LOGIC;
        data_valid    : out STD_LOGIC
    );
end Data_Reader;

architecture Behavioral of Data_Reader is

    type state_type is (IDLE, WAIT_ACK, WAIT_START, READ_CDS, READ_DATA, READ_ERR, READ_WARN, READ_CRC, STOP);
    signal state : state_type;

    signal ma_clk_cnt : integer range 0 to 40 := 0;
    signal ma_clk     : std_logic := '1';
    signal ma_rising  : std_logic;
    signal ma_falling : std_logic;

    signal bit_cnt    : integer range 0 to 64;
    signal shift_reg  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal crc_reg    : std_logic_vector(CRC_WIDTH-1 downto 0);

    -- mark debug signals
    attribute mark_debug : string;
    attribute mark_debug of state : signal is "true";
begin

    -- MA Clock Generation (Simple Divider)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ma_clk_cnt <= 0;
                ma_clk <= '1';
                ma_rising <= '0';
                ma_falling <= '0';
            else
                ma_rising <= '0';
                ma_falling <= '0';
                if state /= IDLE then
                    if ma_clk_cnt = 40 then -- Divide by 10
                        ma_clk_cnt <= 0;
                        ma_clk <= not ma_clk;
                        if ma_clk = '0' then
                            ma_rising <= '1';
                        else
                            ma_falling <= '1';
                        end if;
                    else
                        ma_clk_cnt <= ma_clk_cnt + 1;
                    end if;
                else
                    ma_clk <= '1';
                    ma_clk_cnt <= 0;
                end if;
            end if;
        end if;
    end process;

    biss_ma <= ma_clk;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                position_raw <= (others => '0');
                crc <= (others => '0');
                error_bit <= '0';
                warning_bit <= '0';
                bit_cnt <= 0;
                shift_reg <= (others => '0');
                crc_reg <= (others => '0');
                data_valid <= '0';
            else
                data_valid <= '0';
                case state is
                    when IDLE =>
                        if request_frame = '1' then
                            state <= WAIT_ACK;
                            bit_cnt <= 0;
                            shift_reg <= (others => '0');
                            crc_reg <= (others => '0');
                        end if;

                    when WAIT_ACK =>
                        if ma_rising = '1' then
                            if biss_slo = '0' then
                                state <= WAIT_START;
                            end if;
                        end if;

                    when WAIT_START =>
                        if ma_rising = '1' then
                            if biss_slo = '1' then
                                state <= READ_CDS;
                            end if;
                        end if;

                    when READ_CDS =>
                        if ma_rising = '1' then
                            -- Ignore CDS bit
                            bit_cnt <= 0;
                            state <= READ_DATA;
                        end if;

                    when READ_DATA =>
                        if ma_rising = '1' then
                            shift_reg <= shift_reg(DATA_WIDTH-2 downto 0) & biss_slo;
                            if bit_cnt = DATA_WIDTH - 1 then
                                bit_cnt <= 0;
                                state <= READ_ERR;
                            else
                                bit_cnt <= bit_cnt + 1;
                            end if;
                        end if;

                    when READ_ERR =>
                        if ma_rising = '1' then
                            error_bit <= biss_slo;
                            state <= READ_WARN;
                        end if;

                    when READ_WARN =>
                        if ma_rising = '1' then
                            warning_bit <= biss_slo;
                            bit_cnt <= 0;
                            state <= READ_CRC;
                        end if;

                    when READ_CRC =>
                        if ma_rising = '1' then
                            crc_reg <= crc_reg(CRC_WIDTH-2 downto 0) & biss_slo;
                            if bit_cnt = CRC_WIDTH - 1 then
                                state <= STOP;
                            else
                                bit_cnt <= bit_cnt + 1;
                            end if;
                        end if;

                    when STOP =>
                        position_raw <= shift_reg;
                        crc <= crc_reg;
                        data_valid <= '1';
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
