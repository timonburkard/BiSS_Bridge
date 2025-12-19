library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Data_Provider is
    Generic (
        DATA_WIDTH : integer := 24
    );
    Port (
        clk                : in  STD_LOGIC;
        rst                : in  STD_LOGIC;
        position           : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        position_available : out STD_LOGIC;
        -- AXI4-Stream Master Interface (to be connected to AXI DMA)
        m_axis_aclk    : in  STD_LOGIC;
        m_axis_aresetn : in  STD_LOGIC;
        m_axis_tdata   : out STD_LOGIC_VECTOR (31 downto 0);
        m_axis_tvalid  : out STD_LOGIC;
        m_axis_tready  : in  STD_LOGIC;
        m_axis_tlast   : out STD_LOGIC
    );
end Data_Provider;

architecture Behavioral of Data_Provider is
begin
    -- Implementation placeholder
    position_available <= '0';
end Behavioral;
