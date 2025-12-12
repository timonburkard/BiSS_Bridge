library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Data_Provider is
    Port (
        clk                : in  STD_LOGIC;
        rst                : in  STD_LOGIC;
        position           : in  STD_LOGIC_VECTOR (23 downto 0);
        position_available : out STD_LOGIC;

        -- AXI4-Lite Interface
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
end Data_Provider;

architecture Behavioral of Data_Provider is
begin
    -- Implementation placeholder
    position_available <= '0';
    s_axi_awready <= '0';
    s_axi_wready <= '0';
    s_axi_bresp <= (others => '0');
    s_axi_bvalid <= '0';
    s_axi_arready <= '0';
    s_axi_rdata <= (others => '0');
    s_axi_rresp <= (others => '0');
    s_axi_rvalid <= '0';
end Behavioral;
