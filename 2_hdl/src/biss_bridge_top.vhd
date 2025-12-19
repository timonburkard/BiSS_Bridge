library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BiSS_Bridge_Top is
    Generic (
        DATA_WIDTH    : integer := 24;
        CRC_WIDTH     : integer := 6;
        PULSE_FREQ_HZ : positive := 10_000 -- request pulse frequency
    );
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;

        -- BiSS Interface
        biss_slo      : in  STD_LOGIC;
        biss_ma       : out STD_LOGIC;

        -- Interrupt
        position_available : out STD_LOGIC;

        -- AXI4-Stream Master Interface (from Data Provider to AXI DMA)
        m_axis_aclk    : in  STD_LOGIC;
        m_axis_aresetn : in  STD_LOGIC;
        m_axis_tdata   : out STD_LOGIC_VECTOR (31 downto 0);
        m_axis_tvalid  : out STD_LOGIC;
        m_axis_tready  : in  STD_LOGIC;
        m_axis_tlast   : out STD_LOGIC
    );
end BiSS_Bridge_Top;

architecture Behavioral of BiSS_Bridge_Top is

    component Control is
        generic (
            PULSE_FREQ_HZ : positive := 10_000
        );
        Port (
            clk           : in  STD_LOGIC;
            rst           : in  STD_LOGIC;
            request_frame : out STD_LOGIC
        );
    end component;

    component Data_Reader is
        Generic (
            DATA_WIDTH : integer;
            CRC_WIDTH  : integer
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

    component Data_Checker is
        Generic (
            DATA_WIDTH : integer;
            CRC_WIDTH  : integer
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
    end component;

    component Data_Provider is
        Generic (
            DATA_WIDTH : integer
        );
        Port (
            clk                : in  STD_LOGIC;
            rst                : in  STD_LOGIC;
            position           : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            position_available : out STD_LOGIC;
            m_axis_aclk    : in  STD_LOGIC;
            m_axis_aresetn : in  STD_LOGIC;
            m_axis_tdata   : out STD_LOGIC_VECTOR (31 downto 0);
            m_axis_tvalid  : out STD_LOGIC;
            m_axis_tready  : in  STD_LOGIC;
            m_axis_tlast   : out STD_LOGIC
        );
    end component;

    signal request_frame : STD_LOGIC;
    signal position_raw  : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
    signal crc           : STD_LOGIC_VECTOR (CRC_WIDTH-1 downto 0);
    signal error_bit     : STD_LOGIC;
    signal warning_bit   : STD_LOGIC;
    signal position      : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);


    -- mark debug signals
    attribute mark_debug : string;
    attribute mark_debug of biss_ma : signal is "true";
    attribute mark_debug of biss_slo : signal is "true";
    attribute mark_debug of position_raw : signal is "true";
    attribute mark_debug of position : signal is "true";
    attribute mark_debug of crc : signal is "true";
    attribute mark_debug of error_bit : signal is "true";
    attribute mark_debug of warning_bit : signal is "true";

begin

    inst_Control: Control
    generic map (
        PULSE_FREQ_HZ => PULSE_FREQ_HZ
    )
    port map (
        clk           => clk,
        rst           => rst,
        request_frame => request_frame
    );

    inst_Data_Reader: Data_Reader
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
        crc           => crc,
        error_bit     => error_bit,
        warning_bit   => warning_bit
    );

    inst_Data_Checker: Data_Checker
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        CRC_WIDTH  => CRC_WIDTH
    )
    port map (
        clk          => clk,
        rst          => rst,
        position_raw => position_raw,
        crc          => crc,
        error_bit    => error_bit,
        warning_bit  => warning_bit,
        position     => position
    );

    inst_Data_Provider: Data_Provider
    generic map (
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk                => clk,
        rst                => rst,
        position           => position,
        position_available => position_available,
        m_axis_aclk        => m_axis_aclk,
        m_axis_aresetn     => m_axis_aresetn,
        m_axis_tdata       => m_axis_tdata,
        m_axis_tvalid      => m_axis_tvalid,
        m_axis_tready      => m_axis_tready,
        m_axis_tlast       => m_axis_tlast
    );

end Behavioral;
