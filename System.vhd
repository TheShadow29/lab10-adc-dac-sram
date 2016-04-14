
library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity System is
port ( 
	   ---------ADC interface
	   data_in : in std_logic_vector(7 downto 0);
	   CS, WR, RD : out std_logic;
	   INTR : in std_logic;
	   ---------SRAM interface
	   data_rw : inout std_logic_vector(7 downto 0) := (others => 'Z');
	   we_bar, cs_bar, oe_bar : out std_logic;
	   out_addr : out std_logic_vector(12 downto 0);
	   ---------Outside world interface
	   to_dac : out std_logic_vector(7 downto 0);
	   capture, display : in std_logic;
	   clk, reset : in std_logic
	 );
	 
end entity System;

architecture TopLevelBehave of System is

	signal adc_run, adc_output_ready : std_logic;
	signal adc_data : std_logic_vector(7 downto 0);
	signal mc_start, mc_write, mc_done : std_logic;
	signal mc_read_data, mc_write_data : std_logic_vector(7 downto 0);
	signal address : std_logic_vector(12 downto 0);
	
	
	component ADCC is 
	port ( ------- ADC interface
		 data_in : in std_logic_vector(7 downto 0);
		 CS, WR, RD : out std_logic;
		 INTR : in std_logic;
		 ------- CCU interface
		 adc_run : in std_logic;
		 adc_output_ready : out std_logic;
		 adc_data : out std_logic_vector(7 downto 0);
		 clock, reset : in std_logic );
	end component;

	component smc is
	port
	(
		mc_start : in std_logic;
		mc_write : in std_logic;
		addr : in std_logic_vector (12 downto 0);
		out_addr : out std_logic_vector(12 downto 0);
		mc_writedata : in std_logic_vector (7 downto 0);
		mc_readdata : out std_logic_vector(7 downto 0);
		data_rw : inout std_logic_vector(7 downto 0) := (others => 'Z');
		we_bar, cs_bar, oe_bar : out std_logic;
		clk, reset : in std_logic;
		mc_done : out std_logic
	);
	end component;
	
begin

	adc: ADCC
		 port map
		 (
				adc_run => adc_run,
				adc_output_ready => adc_output_ready,
				data_in => adcc_data_in,
				adc_data => adcc_data_out,
				CS => CS,
				WR => WR,
				RD => RD,
				INTR => INTR,
				clock => clk,
				reset => reset
			);
	
	sram: smc 
		  port map
		  (
		mc_start => mc_start,
		mc_write => mc_write, 
		addr => address,
		out_addr => out_addr,
		mc_writedata => mc_write_data,
		mc_readdata => mc_read_data,
		data_rw => data_rw,
		we_bar => we_bar, 
		cs_bar => cs_bar,
		oe_bar => oe_bar,
		clk => clk,
		reset => reset,
		mc_done => mc_done
	);
	
	ccu_dut: ccu
		     port map
		     (
		     	adc_run => adc_run,
				adc_output_ready => adc_output_ready,
				adc_data => adc_data,
				
				mc_start => mc_start, 
				mc_write => mc_write,
				address => address,
				mc_write_data => mc_write_data,
				mc_read_data => mc_read_data,
				mc_done => mc_done,
				
				clk=>clk, 
				reset=> reset,
				
				capture => capture,	
				display => display
			);
			
end TopLevelBehave;
	   
