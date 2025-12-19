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
        data_valid_in      : in  STD_LOGIC;
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
    signal sample_cnt : integer range 0 to 64 := 0;
    constant BATCH_SIZE : integer := 64; -- 64 * 4 bytes = 256 bytes
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tdata_reg  <= (others => '0');
                tvalid_reg <= '0';
                tlast_reg  <= '0';
                sample_cnt <= 0;
                position_available <= '0';
            else
                position_available <= '0';

                if data_valid_in = '1' then
                    -- New valid sample arrived
                    tdata_reg  <= std_logic_vector(resize(unsigned(position), 32));
                    tvalid_reg <= '1';
                    
                    if sample_cnt = BATCH_SIZE - 1 then
                        tlast_reg <= '1';
                        sample_cnt <= 0;
                        position_available <= '1'; -- Interrupt on packet complete
                    else
                        tlast_reg <= '0';
                        sample_cnt <= sample_cnt + 1;
                    end if;
                elsif (tvalid_reg = '1') and (m_axis_tready = '1') then
                    -- Handshake complete
                    tvalid_reg <= '0';
                    tlast_reg  <= '0';
                end if;
            end if;
        end if;
    end process;

    m_axis_tdata  <= tdata_reg;
    m_axis_tvalid <= tvalid_reg;
    m_axis_tlast  <= tlast_reg;

end Behavioral;
