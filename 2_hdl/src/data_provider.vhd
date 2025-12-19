library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
    signal tdata_reg  : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal tvalid_reg : STD_LOGIC := '0';
    signal tlast_reg  : STD_LOGIC := '0';
    signal prev_pos   : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0');
    signal has_data   : STD_LOGIC := '0';
begin
    -- Present data on AXIS when `position` changes.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tdata_reg  <= (others => '0');
                tvalid_reg <= '0';
                tlast_reg  <= '0';
                prev_pos   <= (others => '0');
                has_data   <= '0';
                position_available <= '0';
            else
                -- capture new position and start transfer
                if (position /= prev_pos) and (has_data = '0') then
                    -- sign-extend `position` to 32 bits
                    tdata_reg  <= std_logic_vector(resize(signed(position), 32));
                    tvalid_reg <= '1';
                    tlast_reg  <= '1';
                    has_data   <= '1';
                    position_available <= '1';
                    prev_pos <= position;
                elsif (tvalid_reg = '1') and (m_axis_tready = '1') then
                    -- transfer accepted by slave
                    tvalid_reg <= '0';
                    tlast_reg  <= '0';
                    has_data   <= '0';
                    position_available <= '0';
                end if;
            end if;
        end if;
    end process;

    m_axis_tdata  <= tdata_reg;
    m_axis_tvalid <= tvalid_reg;
    m_axis_tlast  <= tlast_reg;

end Behavioral;
