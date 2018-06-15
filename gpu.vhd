library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpu is
    generic
    (
        constant screen_width    : integer := 640;
        constant screen_height    : integer := 460;
        constant address_space    : integer := 9200
    );
    port
    (
        --Avalon MM Slave interface
        slv_clock    : in std_logic;
        slv_resetn    : in std_logic;
        
        slv_read    : in std_logic;
        slv_write    : in std_logic;

        slv_address    : in std_logic_vector(1 downto 0);
        slv_writedata   : in std_logic_vector(31 downto 0);
        slv_byteenable  : in std_logic_vector(3 downto 0);
        
        slv_readdata    : out std_logic_vector(31 downto 0);

        --Avalon MM Master interface
        m_clock    : in std_logic;
        m_reset    : in std_logic;
        
        m_read    : out std_logic;
        m_write    : out std_logic;
        
        m_address    : out std_logic_vector(19 downto 0);
        m_writedata    : out std_logic_vector(31 downto 0);
        m_readdata    : in std_logic_vector(31 downto 0)
        
        
    );
end gpu;

architecture behavioral of gpu is
    --Slave internal registers
    signal slv_point1 : std_logic_vector(31 downto 0);                --Address 00
    signal slv_point2 : std_logic_vector(31 downto 0);                --Address 01
    signal slv_flag_register    : std_logic_vector(31 downto 0);        --Address 10
    
    --Master internal    
    signal m_busy_flag : std_logic;
    signal m_pixel_counter : unsigned(19 downto 0);
    signal m_max_pix_cnt : unsigned(19 downto 0);
--    signal m_address_counter : unsigned(19 downto 0);
    signal m_current_word : std_logic_vector(31 downto 0);
    signal m_point1 : std_logic_vector(31 downto 0);
    signal m_point2 : std_logic_vector(31 downto 0);
    
    type state_t is (idle, read_word, draw_pixels, write_word);

    signal state : state_t;

begin

    slave_registers: process(slv_clock)

    begin
        if rising_edge(slv_clock) then
            if slv_resetn = '1' then
                slv_point1 <= (others => '0');
                slv_point2 <= (others => '0');
            else
                if slv_write = '1' then
                    if slv_address = "00" then
                        if slv_byteenable(0) = '1' then
                            slv_point1(7 downto 0) <= slv_writedata(7 downto 0);
                        end if;
                        
                        if slv_byteenable(1) = '1' then
                            slv_point1(15 downto 8) <= slv_writedata(15 downto 8);
                        end if;
                        
                        if slv_byteenable(2) = '1' then
                            slv_point1(23 downto 16) <= slv_writedata(23 downto 16);
                        end if;
                        
                        if slv_byteenable(3) = '1' then
                            slv_point1(31 downto 24) <= slv_writedata(31 downto 24);
                        end if;
        
                    elsif slv_address = "01" then
                        if slv_byteenable(0) = '1' then
                            slv_point2(7 downto 0) <= slv_writedata(7 downto 0);
                        end if;
                        
                        if slv_byteenable(1) = '1' then
                            slv_point2(15 downto 8) <= slv_writedata(15 downto 8);
                        end if;
                        
                        if slv_byteenable(2) = '1' then 
                            slv_point2(23 downto 16) <= slv_writedata(23 downto 16);
                        end if;
                        
                        if slv_byteenable(3) = '1' then
                            slv_point2(31 downto 24) <= slv_writedata(31 downto 24);
                        end if;
                    end if;

                end if;
                
                if slv_read = '1' then
                    if slv_address = "00" then
                        slv_readdata <= slv_point1;
                    elsif slv_address = "01" then
                        slv_readdata <= slv_point2;
                    elsif slv_address = "10" then
                        slv_readdata <= slv_flag_register;
                    end if;
                end if;
            end if;
        end if;        
    end process;
    
    gpu: process(m_clock)
    
    begin
        if rising_edge(m_clock) then
            if m_reset = '1' then
                state <= idle;
                m_busy_flag <= '0';
                m_pixel_counter <= (others => '0');
                m_point1 <= (others => '0');
                m_point2 <= (others => '0');
            else
                case state is
                    when idle =>
                    
                    when read_word =>
                    
                    when draw_pixels =>
                    
                    when write_word =>
                    
                    when others =>
                        null;        
--    if rising_edge(m_clock) then
--        if m_reset = '1' then
--            m_busy_flag <= '0';
--            m_pixel_counter <= (others => '0');
----            m_address_counter <= (others => '0');
--            m_point1 <= (others => '0');
--            m_point2 <= (others => '0');
--        else
--            if m_busy_flag = '0' and slv_point1 /= m_point1 and slv_point2 /= m_point2 then
--                m_busy_flag <= '1';
--                m_point1 <= slv_point1;
--                m_point2 <= slv_point2;
--            end if;
--            
--            if m_busy_flag = '1' then    
--                if m_pixel_counter = (screen_height * screen_width) - 1 then
--                    m_pixel_counter <= (others => '0');
--                    m_busy_flag <= '0';
----                elsif (m_pixel_counter(4 downto 0) = "00000") and (m_pixel_counter /= (others => '0')) then
----                    m_address_counter <= m_address_counter + 4;
--                else
--                    m_pixel_counter <= m_pixel_counter + 1;
--                end if;
--
--            end if;
--            
--            
--        end if;
--    end if;

    end process;
    

end behavioral;