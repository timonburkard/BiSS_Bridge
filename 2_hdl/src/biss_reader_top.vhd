library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BiSS_Reader_Top is
    Generic (
        DATA_WIDTH : integer := 24;
        CRC_WIDTH  : integer := 6
    );
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;

        -- BiSS Interface
        biss_slo      : in  STD_LOGIC;
        biss_ma       : out STD_LOGIC;

        -- Interrupt
        position_available : out STD_LOGIC;

        -- AXI4-Lite Interface (for Data Provider)
        s_axi_aclk    : in  STD_LOGIC;
        s_axi_aresetn : in  STD_LOGIC;
        s_axi_awaddr  : in  STD_LOGIC_VECTOR(3 downto 0);
        s_axi_awprot  : in  STD_LOGIC_VECTOR(2 downto 0);
        s_axi_awvalid : in  STD_LOGIC;
        s_axi_awready : out STD_LOGIC;
        s_axi_wdata   : in  STD_LOGIC_VECTOR(31 downto 0);
        s_axi_wstrb   : in  STD_LOGIC_VECTOR(3 downto 0);
        s_axi_wvalid  : in  STD_LOGIC;
        s_axi_wready  : out STD_LOGIC;
        s_axi_bresp   : out STD_LOGIC_VECTOR(1 downto 0);
        s_axi_bvalid  : out STD_LOGIC;
        s_axi_bready  : in  STD_LOGIC;
        s_axi_araddr  : in  STD_LOGIC_VECTOR(3 downto 0);
        s_axi_arprot  : in  STD_LOGIC_VECTOR(2 downto 0);
        s_axi_arvalid : in  STD_LOGIC;
        s_axi_arready : out STD_LOGIC;
        s_axi_rdata   : out STD_LOGIC_VECTOR(31 downto 0);
        s_axi_rresp   : out STD_LOGIC_VECTOR(1 downto 0);
        s_axi_rvalid  : out STD_LOGIC;
        s_axi_rready  : in  STD_LOGIC
    );
end BiSS_Reader_Top;

architecture Behavioral of BiSS_Reader_Top is

    component Control is
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
            s_axi_aclk    : in  STD_LOGIC;
            s_axi_aresetn : in  STD_LOGIC;
            s_axi_awaddr  : in  STD_LOGIC_VECTOR(3 downto 0);
            s_axi_awprot  : in  STD_LOGIC_VECTOR(2 downto 0);
            s_axi_awvalid : in  STD_LOGIC;
            s_axi_awready : out STD_LOGIC;
            s_axi_wdata   : in  STD_LOGIC_VECTOR(31 downto 0);
            s_axi_wstrb   : in  STD_LOGIC_VECTOR(3 downto 0);
            s_axi_wvalid  : in  STD_LOGIC;
            s_axi_wready  : out STD_LOGIC;
            s_axi_bresp   : out STD_LOGIC_VECTOR(1 downto 0);
            s_axi_bvalid  : out STD_LOGIC;
            s_axi_bready  : in  STD_LOGIC;
            s_axi_araddr  : in  STD_LOGIC_VECTOR(3 downto 0);
            s_axi_arprot  : in  STD_LOGIC_VECTOR(2 downto 0);
            s_axi_arvalid : in  STD_LOGIC;
            s_axi_arready : out STD_LOGIC;
            s_axi_rdata   : out STD_LOGIC_VECTOR(31 downto 0);
            s_axi_rresp   : out STD_LOGIC_VECTOR(1 downto 0);
            s_axi_rvalid  : out STD_LOGIC;
            s_axi_rready  : in  STD_LOGIC
        );
    end component;

    signal request_frame : STD_LOGIC;
    signal position_raw  : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
    signal crc           : STD_LOGIC_VECTOR (CRC_WIDTH-1 downto 0);
    signal error_bit     : STD_LOGIC;
    signal warning_bit   : STD_LOGIC;
    signal position      : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);

begin

    inst_Control: Control
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
        s_axi_aclk         => s_axi_aclk,
        s_axi_aresetn      => s_axi_aresetn,
        s_axi_awaddr       => s_axi_awaddr,
        s_axi_awprot       => s_axi_awprot,
        s_axi_awvalid      => s_axi_awvalid,
        s_axi_awready      => s_axi_awready,
        s_axi_wdata        => s_axi_wdata,
        s_axi_wstrb        => s_axi_wstrb,
        s_axi_wvalid       => s_axi_wvalid,
        s_axi_wready       => s_axi_wready,
        s_axi_bresp        => s_axi_bresp,
        s_axi_bvalid       => s_axi_bvalid,
        s_axi_bready       => s_axi_bready,
        s_axi_araddr       => s_axi_araddr,
        s_axi_arprot       => s_axi_arprot,
        s_axi_arvalid      => s_axi_arvalid,
        s_axi_arready      => s_axi_arready,
        s_axi_rdata        => s_axi_rdata,
        s_axi_rresp        => s_axi_rresp,
        s_axi_rvalid       => s_axi_rvalid,
        s_axi_rready       => s_axi_rready
    );

end Behavioral;