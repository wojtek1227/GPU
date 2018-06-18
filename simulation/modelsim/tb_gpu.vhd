
-- vhdl test bench template for design  :  gpu
-- 
-- simulation tool : modelsim-altera (vhdl)
-- 

library ieee;                                               
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_gpu is
end tb_gpu;

architecture tb_arch of tb_gpu is

	component gpu
		port(
		slv_read		:	 in std_logic;
		slv_write		:	 in std_logic;
		slv_address		:	 in std_logic_vector(1 downto 0);
		slv_writedata   :	 in std_logic_vector(31 downto 0);
		slv_byteenable  :	 in std_logic_vector(3 downto 0);
		slv_readdata    :	 out std_logic_vector(31 downto 0);
		clock		    :	 in std_logic;
		reset		    :	 in std_logic;
		m_waitrequest   :	 in std_logic;
		m_read		    :	 out std_logic;
		m_write		    :	 out std_logic;
		m_address       :	 out std_logic_vector(15 downto 0);
		m_writedata		:	 out std_logic_vector(31 downto 0);
		m_readdata		:	 in std_logic_vector(31 downto 0)
        );
	end component;
	
	-- constants
	constant clock_period     : time := 10 ns;
    
    --types
    
    type state_t is (idle, read_word, read_delay, write_word);

	
	--stimulus signals
	
	signal clock          : std_logic;
	signal m_readdata       : std_logic_vector(31 downto 0);
	signal reset          : std_logic;
    signal m_waitrequest    : std_logic;
	
    signal slv_address      : std_logic_vector(1 downto 0);
	signal slv_byteenable   : std_logic_vector(3 downto 0);
	signal slv_read         : std_logic;
	signal slv_write        : std_logic;
	signal slv_writedata    : std_logic_vector(31 downto 0);

	
	--observed signals
	signal slv_readdata     : std_logic_vector(31 downto 0);
	
	signal m_writedata      : std_logic_vector(31 downto 0);
	signal m_address        : std_logic_vector(15 downto 0);
	signal m_write          : std_logic;
	signal m_read           : std_logic;
    
	signal end_sim: boolean := false;
	
begin
		uut : gpu
		port map 
		(
			m_address => m_address,
			clock => clock,
			m_read => m_read,
			m_readdata => m_readdata,
			reset => reset,
			m_write => m_write,
			m_writedata => m_writedata,
            m_waitrequest => m_waitrequest,
			slv_address => slv_address,
			slv_byteenable => slv_byteenable,
			slv_read => slv_read,
			slv_readdata => slv_readdata,
			slv_write => slv_write,
			slv_writedata => slv_writedata
		);   
    
    stimulus : process 
    
        --Slave
        alias slv_point_up_left is <<signal .tb_gpu.uut.slv_point_up_left : std_logic_vector(31 downto 0)>>;
        alias slv_point_down_right is <<signal .tb_gpu.uut.slv_point_down_right : std_logic_vector(31 downto 0)>>;
        alias slv_flag_register is <<signal .tb_gpu.uut.slv_flag_register : std_logic_vector(31 downto 0)>>;
        --Master
        alias m_busy_flag is <<signal .tb_gpu.uut.m_busy_flag : std_logic>>;
        alias m_point_up_left is <<signal .tb_gpu.uut.m_point_up_left : std_logic_vector(18 downto 0)>>;
        alias m_point_up_right is <<signal .tb_gpu.uut.m_point_up_right : std_logic_vector(18 downto 0)>>;
        alias m_point_down_right is <<signal .tb_gpu.uut.m_point_down_right : std_logic_vector(18 downto 0)>>;
        alias m_curr_point is <<signal .tb_gpu.uut.m_curr_point : std_logic_vector(18 downto 0)>>;
        
        alias m_data_ready is <<signal .tb_gpu.uut.m_data_ready : std_logic>>;
        alias m_data_prepared is <<signal .tb_gpu.uut.m_data_prepared : std_logic_vector(31 downto 0)>>;
        
        alias m_curr_state is <<signal .tb_gpu.uut.m_curr_state : state_t>>;
    
        procedure init_master is
            variable l : line;
        begin
            writeline(output, l);
            write(l, string'("----Init_master----" & to_string(now, UNIT => ns)));
            writeline(output, l);
            reset <= '0';
            m_readdata <= (others => '0');
            m_waitrequest <= '0';
        end init_master;
        
        procedure init_slave is
        variable l : line;
        begin
            writeline(output, l);
            write(l, string'("----Init_slave----" & to_string(now, UNIT => ns)));
            writeline(output, l);
            slv_read <= '0';
            slv_write <= '0';
            slv_address <= (others => '0');
            slv_writedata <= (others => '0');
            slv_byteenable <= (others => '0');
        end init_slave;

        procedure test_reset is
        variable l : line;
        begin
            writeline(output, l);
            write(l, string'("----Test_reset @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            wait until falling_edge(clock);
            reset <= '1';
            wait until falling_edge(clock);
            reset <= '0';
        end test_reset;
        
        procedure test_slv_write
       (data_at_00 : in std_logic_vector(31 downto 0);
        data_at_01 : in std_logic_vector(31 downto 0);
        data_at_10 : in std_logic_vector(31 downto 0)) is
        variable l : line;

        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_write_slave start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            slv_address <= "00";
            slv_write <= '1';
            slv_writedata <= data_at_00;
            slv_byteenable <= (others => '1');
            
            wait until falling_edge(clock);
            assert (slv_point_up_left = data_at_00) report "writing to 00 failed" severity error;
            
            slv_address <= "01";
            slv_writedata <= data_at_01;
            wait until falling_edge(clock);
            assert (slv_point_down_right = data_at_01) report "writing to 01 failed" severity error;
            
            slv_address <= "10";
            slv_writedata <= data_at_10;
            slv_byteenable <= "0001";
            
            wait until falling_edge(clock);
            slv_write <= '0';
            assert (slv_flag_register(16 downto 0) = data_at_10(16 downto 0)) report "writing to 10 failed" severity error;
            writeline(output, l);
            write(l, string'("----Test_write_slave end @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_slv_write;
        
        procedure test_case_1a is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_1a start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0000", X"0002_003f", X"0000_0001");
            wait until slv_flag_register(16) = '0';

            writeline(output, l);
            write(l, string'("----Test_case_1a ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_1a;
        
        procedure test_case_1b is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_1b start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0040", X"0002_007f", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_1b ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_1b;
        
        procedure test_case_2a is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_2a start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0000", X"0002_0034", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_2a ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_2a; 
        
        procedure test_case_2b is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_2b start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0040", X"0002_0074", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_2b ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_2b; 
        
        procedure test_case_3a is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_3a start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0001", X"0002_003f", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_3a ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_3a;
       
      procedure test_case_3b is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_3b start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0041", X"0002_007f", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_3b ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_3b;
       
        procedure test_case_4a is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_4a start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0001", X"0002_0034", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_4a ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_4a;
       
        procedure test_case_4b is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_4b start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0041", X"0002_0074", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_4b ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_4b;  
        
        procedure test_case_5a is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_5a start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0001", X"0002_0014", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_5a ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_5a;
       
        procedure test_case_5b is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_5b start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0041", X"0002_0054", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_5b ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_5b;
        
        procedure test_case_6a is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_6a start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0001", X"0002_0020", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_6a ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_6a;
       
        procedure test_case_6b is
        variable l : line;
        
        begin
            wait until falling_edge(clock);
            writeline(output, l);
            write(l, string'("----Test_case_6b start @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            test_slv_write(X"0000_0041", X"0002_0060", X"0000_0001");
            wait until slv_flag_register(16) = '0';
            writeline(output, l);
            write(l, string'("----Test_case_6b ends @: " & to_string(now, UNIT => ns)));
            writeline(output, l);
            
        end test_case_6b;
        
	begin
        init_master;
        init_slave;
        wait until falling_edge(clock);
        test_reset;
        test_slv_write((others => '0'), X"0000_003f", X"0000_0001");
        
        test_case_1a;
        
        test_reset;
        test_case_1b;
        
        test_case_2a;
        
        test_case_2b;
        
        test_case_3a;
        
        test_case_3b;
        
        test_case_4a;
        
        test_case_4b;
        
        test_case_5a;
        
        test_case_5b;
        
        test_case_6a;
        
        test_case_6b;

--        wait until m_busy_flag = 0;
		wait for 500 ns;
		end_sim <= true;
	wait;                                                        
	end process stimulus; 

	
	clock_process : process
	begin
		if end_sim = false then
			clock <= '0';
			wait for clock_period/2;
		else
			wait;
		end if;
		if end_sim = false then
			clock <= '1';
			wait for clock_period/2;
		else
			wait;
		end if;
	end process;
	
end tb_arch;
