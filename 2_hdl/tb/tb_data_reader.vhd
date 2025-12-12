library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tb_Data_Reader is
end tb_Data_Reader;

architecture Behavioral of tb_Data_Reader is

    component Data_Reader is
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
            warning_bit   : out STD_LOGIC
        );
    end component;

    -- Constants
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
    constant REQ_PERIOD : time := 100 us; -- 10 kHz
    constant DATA_WIDTH : integer := 24;
    constant CRC_WIDTH  : integer := 6;

    -- Signals
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal request_frame : std_logic := '0';
    signal biss_slo      : std_logic := '1';
    signal biss_ma       : std_logic;
    signal position_raw  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal crc_out       : std_logic_vector(CRC_WIDTH-1 downto 0);
    signal error_bit     : std_logic;
    signal warning_bit   : std_logic;

    -- Simulation Control
    signal sim_running   : boolean := true;

begin

    -- Instantiate DUT
    uut: Data_Reader
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            CRC_WIDTH  => CRC_WIDTH
        )
        port map (
            clk           => clk,
            rst           => rst,
            request_frame => request_frame,
            biss_slo      => biss_slo,
            biss_ma       => biss_ma,
            position_raw  => position_raw,
            crc           => crc_out,
            error_bit     => error_bit,
            warning_bit   => warning_bit
        );

    -- Clock Generation
    clk_process: process
    begin
        while sim_running loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimuli Process (Reset and Request)
    stim_process: process
    begin
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        -- Run for a few frames
        for i in 1 to 50 loop
            request_frame <= '1';
            wait for CLK_PERIOD; -- Single cycle pulse
            request_frame <= '0';
            wait for REQ_PERIOD - CLK_PERIOD;
        end loop;

        sim_running <= false;
        wait;
    end process;

    -- BiSS Slave Emulation Process
    slave_process: process
        variable v_angle : real := 0.0;
        variable v_data  : integer;
        variable v_data_slv : std_logic_vector(DATA_WIDTH-1 downto 0);
        variable v_crc   : std_logic_vector(CRC_WIDTH-1 downto 0);

        -- Sine wave parameters
        constant AMPLITUDE : real := real(2**(DATA_WIDTH-2));
        constant OFFSET    : real := real(2**(DATA_WIDTH-2));
        constant STEP      : real := 0.2; -- Phase step per frame

    begin
        wait until rst = '0';

        while sim_running loop
            -- Wait for MA clock to start (falling edge indicates start of transmission from IDLE)
            wait until falling_edge(biss_ma);

            -- Calculate Data (Sine Wave)
            v_data := integer(OFFSET + AMPLITUDE * sin(v_angle));
            v_data_slv := std_logic_vector(to_unsigned(v_data, DATA_WIDTH));
            v_angle := v_angle + STEP;

            -- Calculate CRC (Dummy value 0x2A)
            v_crc := std_logic_vector(to_unsigned(42, CRC_WIDTH));

            -- Send ACK (0)
            biss_slo <= '0';

            -- Send START (1)
            wait until falling_edge(biss_ma);
            biss_slo <= '1';

            -- Send CDS (0)
            wait until falling_edge(biss_ma);
            biss_slo <= '0';

            -- Send Data
            for i in DATA_WIDTH-1 downto 0 loop
                wait until falling_edge(biss_ma);
                biss_slo <= v_data_slv(i);
            end loop;

            -- Send Error (1 = OK)
            wait until falling_edge(biss_ma);
            biss_slo <= '1';

            -- Send Warning (1 = OK)
            wait until falling_edge(biss_ma);
            biss_slo <= '1';

            -- Send CRC
            for i in CRC_WIDTH-1 downto 0 loop
                wait until falling_edge(biss_ma);
                biss_slo <= v_crc(i);
            end loop;

            -- Stop / Timeout (Back to IDLE)
            wait until falling_edge(biss_ma);
            biss_slo <= '1';

        end loop;
        wait;
    end process;

end Behavioral;
