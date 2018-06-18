library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpu is
    generic
    (
        constant screen_width   : integer := 640;
        constant screen_height  : integer := 460;
        constant address_space  : integer := 9200;
        
        constant m_address_width : integer := 16;
        constant m_data_witdh   : integer := 32
    );
    port
    (
        clock           : in std_logic;
        reset           : in std_logic;
            
        --Avalon MM Slave interface
        slv_read        : in std_logic;
        slv_write       : in std_logic;

        slv_address     : in std_logic_vector(1 downto 0);
        slv_writedata   : in std_logic_vector(31 downto 0);
        slv_byteenable  : in std_logic_vector(3 downto 0);
        
        slv_readdata    : out std_logic_vector(31 downto 0);

        --Avalon MM Master interface      
        m_waitrequest   : in std_logic;
        m_read          : out std_logic;
        m_write         : out std_logic;
        
        m_address       : out std_logic_vector(m_address_width - 1 downto 0);
        m_writedata     : out std_logic_vector(m_data_witdh - 1 downto 0);
        m_readdata      : in std_logic_vector(m_data_witdh - 1 downto 0)
        
        
    );
end gpu;

architecture behavioral of gpu is
    --Slave internal registers
    signal slv_point_up_left    : std_logic_vector(31 downto 0);                --Address 00      |----Y1----|----X1----|
    signal slv_point_down_right : std_logic_vector(31 downto 0);                --Address 01      |----Y2----|----X2----|
    signal slv_flag_register    : std_logic_vector(31 downto 0);                --Address 10      |--flags---|---ctrl---|
    
    --Master internal    
    signal m_busy_flag          : std_logic;
    signal m_point_up_left      : unsigned(18 downto 0);
    signal m_point_up_right     : unsigned(18 downto 0);
    signal m_point_down_right   : unsigned(18 downto 0);
    signal m_curr_point         : unsigned(18 downto 0);
    
    signal m_data_ready         : std_logic;
    signal m_data_prepared      : std_logic_vector(m_data_witdh - 1 downto 0);
        
    type state_t is (idle, read_word, read_delay, write_word);

    signal m_curr_state : state_t;
    
begin

    slv_flag_register(16) <= m_busy_flag;
    
    slave_registers: process(clock)

    begin
        if rising_edge(clock) then
            if reset = '1' then
                slv_point_up_left <= (others => '0');
                slv_point_down_right <= (others => '0');
                slv_flag_register(15 downto 0) <= (others => '0');
                slv_readdata <= (others => '0');
            else
                if slv_write = '1' then
                    if slv_address = "00" then
                        if slv_byteenable(0) = '1' then
                            slv_point_up_left(7 downto 0) <= slv_writedata(7 downto 0);
                        end if;
                        
                        if slv_byteenable(1) = '1' then
                            slv_point_up_left(15 downto 8) <= slv_writedata(15 downto 8);
                        end if;
                        
                        if slv_byteenable(2) = '1' then
                            slv_point_up_left(23 downto 16) <= slv_writedata(23 downto 16);
                        end if;
                        
                        if slv_byteenable(3) = '1' then
                            slv_point_up_left(31 downto 24) <= slv_writedata(31 downto 24);
                        end if;
        
                    elsif slv_address = "01" then
                        if slv_byteenable(0) = '1' then
                            slv_point_down_right(7 downto 0) <= slv_writedata(7 downto 0);
                        end if;
                        
                        if slv_byteenable(1) = '1' then
                            slv_point_down_right(15 downto 8) <= slv_writedata(15 downto 8);
                        end if;
                        
                        if slv_byteenable(2) = '1' then 
                            slv_point_down_right(23 downto 16) <= slv_writedata(23 downto 16);
                        end if;
                        
                        if slv_byteenable(3) = '1' then
                            slv_point_down_right(31 downto 24) <= slv_writedata(31 downto 24);
                        end if;
                        
                    elsif slv_address = "10" then
                        if slv_byteenable(0) = '1' then
                            slv_flag_register(7 downto 0) <= slv_writedata(7 downto 0);
                        end if;
                        if slv_byteenable(1) = '1' then
                            slv_flag_register(15 downto 8) <= slv_writedata(15 downto 8);
                        end if;
                    end if;
                else
                    if m_busy_flag = '1' then
                        slv_flag_register(0) <= '0';
                    end if;
                end if;
                
                if slv_read = '1' then
                    if slv_address = "00" then
                        slv_readdata <= slv_point_up_left;
                    elsif slv_address = "01" then
                        slv_readdata <= slv_point_down_right;
                    elsif slv_address = "10" then
                        slv_readdata <= slv_flag_register;
                    end if;
                end if;
            end if;
        end if;        
    end process;
    
    gpu: process(clock)
 
    begin
        if rising_edge(clock) then
            if reset = '1' then
                m_read <= '0';
                m_write <= '0';
                m_address <= (others => '0');
                m_writedata <= (others => '0');
                
                m_curr_state <= idle;
                m_busy_flag <= '0';
                slv_flag_register(31 downto 17) <= (others => '0');
                m_point_up_left <= (others => '0');
                m_point_up_right <= (others => '0');
                m_point_down_right <= (others => '0');
                m_curr_point <= (others => '0');
                m_data_ready <= '0';
                m_data_prepared <= (others => '0');
            else
                case m_curr_state is
                    when idle =>
                        m_write <= '0';
                        if slv_flag_register(0) = '1' then
                            if unsigned(slv_point_up_left(31 downto 16)) < screen_width and
                                unsigned(slv_point_up_left(15 downto 0)) < screen_height and
                                unsigned(slv_point_down_right(31 downto 16)) < screen_width and
                                unsigned(slv_point_down_right(15 downto 0)) < screen_height then
                                if unsigned(slv_point_up_left(31 downto 16)) <= unsigned(slv_point_down_right(31 downto 16)) and
                                    unsigned(slv_point_up_left(15 downto 0)) < unsigned(slv_point_down_right(15 downto 0)) then
                                        m_busy_flag <= '1';
                                        m_point_up_left <= to_unsigned(screen_width, 10) * resize((unsigned(slv_point_up_left(25 downto 16))), 9) + resize(unsigned(slv_point_up_left(15 downto 0)), 19);
                                        m_curr_point <= to_unsigned(screen_width, 10) * resize((unsigned(slv_point_up_left(25 downto 16))), 9) + resize(unsigned(slv_point_up_left(15 downto 0)), 19);
                                        m_point_up_right <= to_unsigned(screen_width, 10) * resize((unsigned(slv_point_up_left(25 downto 16))), 9) + resize(unsigned(slv_point_down_right(15 downto 0)), 19);
                                        m_point_down_right <= to_unsigned(screen_width, 10) * resize((unsigned(slv_point_down_right(25 downto 16))), 9) + resize(unsigned(slv_point_down_right(15 downto 0)), 19);
                                        if slv_point_up_left(4 downto 0) = "00000" then
                                            m_curr_state <= write_word;
                                        else
                                            m_curr_state <= read_word;
                                        end if;
                                end if;
                            end if;
                        end if;
                        
                    when read_word =>
                        m_write <= '0';
                        if (m_point_up_right - m_curr_point >= 31) then
                            for i in 0 to 31 loop
                                if i >= to_integer(m_curr_point(4 downto 0)) then
                                    m_data_prepared(i) <= '1';
                                else
                                    m_data_prepared(i) <= '0';
                                end if;
                            end loop;
                        else
                            for i in 0 to 31 loop
                                if (i <= to_integer(m_point_up_right(4 downto 0))) and (i >= to_integer(m_curr_point(4 downto 0))) then
                                    m_data_prepared(i) <= '1';
                                else
                                    m_data_prepared(i) <= '0';
                                end if;
                            end loop;
                        end if;
                        m_read <= '1';
                        m_address <= std_logic_vector(m_curr_point(18 downto 3));
                        if m_waitrequest = '1' then
                            m_curr_state <= read_word;
                        else
                            m_curr_state <= read_delay;
                        end if;

                    when read_delay =>
                        m_data_ready <= '1';
                        m_read <= '0';
                        m_curr_state <= write_word;
                        
                    when write_word =>
                        if m_curr_point(4 downto 0) = "00000" then
                            if (m_point_up_right - m_curr_point > 31) then
                                m_write <= '1';
                                m_writedata <= (others => '1');
                                m_address <= std_logic_vector(m_curr_point(18 downto 3));
                                if m_waitrequest = '0' then
                                    m_curr_point <= m_curr_point + 32;
                                end if;
                                m_curr_state <= write_word;
                            elsif (m_point_up_right - m_curr_point = 31) then
                                m_write <= '1';
                                m_writedata <= (others => '1');
                                m_address <= std_logic_vector(m_curr_point(18 downto 3));
                                if m_waitrequest = '0' then
                                    if m_point_up_right = m_point_down_right then
                                        m_curr_state <= idle;
                                        m_busy_flag <= '0';
                                    else
                                        m_curr_point <= m_Point_up_left + 640;
                                        m_point_up_right <= m_point_up_right + 640;
                                        m_point_up_left <= m_point_up_left + 640;
                                        m_curr_state <= write_word;
                                    end if;
                                end if;
                            else
                                if (m_data_ready = '1') then
                                    m_write <= '1';
                                    m_writedata <= m_readdata or m_data_prepared;
                                    m_address <= std_logic_vector(m_curr_point(18 downto 3));
                                    if m_waitrequest = '0' then
                                        if m_point_up_right = m_point_down_right then
                                            m_curr_state <= idle;
                                            m_busy_flag <= '0';
                                        else
                                            m_curr_point <= m_Point_up_left + 640;
                                            m_point_up_right <= m_point_up_right + 640;
                                            m_point_up_left <= m_point_up_left + 640;
                                            m_curr_state <= write_word;
                                        end if; 
                                        m_data_ready <= '0';
                                    end if;
                                else
                                    m_curr_state <= read_word;
                                end if;
                            end if;
                        else
                            if m_data_ready = '1' then
                                if (m_point_up_right - m_curr_point >= 31) then
                                    m_write <= '1';
                                    m_writedata <= m_readdata or m_data_prepared;
                                    m_address <= std_logic_vector(m_curr_point(18 downto 3));
                                    if m_waitrequest = '0' then
                                        m_curr_point <= (m_curr_point(18 downto 3) & "000") + 32;
                                        m_curr_state <= write_word;
                                    end if;
                                else
                                    m_write <= '1';
                                    m_writedata <= m_readdata or m_data_prepared;
                                    m_address <= std_logic_vector(m_curr_point(18 downto 3));
                                    if m_waitrequest = '0' then
                                        if m_point_up_right = m_point_down_right then
                                            m_curr_state <= idle;
                                            m_busy_flag <= '0';
                                        else
                                            m_curr_point <= m_Point_up_left + 640;
                                            m_point_up_right <= m_point_up_right + 640;
                                            m_point_up_left <= m_point_up_left + 640;
                                            m_curr_state <= write_word;
                                        end if;
                                    end if;
                                end if;
                                m_data_ready <= '0';
                            else
                                m_curr_state <= read_word;
                            end if;
                        end if;
                    
                    when others =>
                        null;        
                    

                end case;
            end if;
        end if;

    end process;
    

end behavioral;