library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

package sram_package is
	component adder13 is
		port 
		(
			A, B : in std_logic_vector(12 downto 0);
			Result : out std_logic_vector(12 downto 0)
		);
	end component;

	component data_register is
	  generic (data_width:integer);
		port (Din: in std_logic_vector(data_width-1 downto 0);
		      Dout: out std_logic_vector(data_width-1 downto 0);
		      clk, enable: in std_logic);
	end component;

	component data_register_int is
		port (Din: in integer;
	      Dout: out integer;
	      clk, enable: in std_logic);
	end component;

	component wtime is
		port
		(
			start : in std_logic;
			done : out std_logic;
			repeat_n : in integer;
			clk, reset : in std_logic	
		);
	end component;

	component wtime_cp is
		port
		(
			Tv : out std_logic_vector;
			Sv : in std_logic_vector;
			clk, reset : std_logic;
			start : in std_logic;
			done : out std_logic 
		);
	end component;

	component wtime_dp is
		port
		(
			Tv : in std_logic_vector;
			Sv : out std_logic_vector;
			clk, reset : in std_logic;
			repeat_n : in integer
		);
	end component;
	component data_register_bin is
		port (Din: in std_logic;
	      Dout: out std_logic;
	      clk, enable: in std_logic);
	end component;
	component adcc is
		port
		(
			adc_run : in std_logic;
			adc_output_ready : out std_logic;
			adcc_data_in : in std_logic_vector(7 downto 0);
			adcc_data_out : out std_logic_vector(7 downto 0);
			cs_bar : out std_logic;
			wr_bar : out std_logic;
			rd_bar : out std_logic;
			intr_bar : in std_logic;
			clk : in std_logic;
			reset : in std_logic
		);
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

	component sram_main is
    generic  (
        constant tAA:   time := 45 ns; -- 6116 static CMOS RAM 
        constant tACS:  time := 45 ns; 
        constant tCLZ:  time := 5 ns; 
        constant tCHZ:  time := 20 ns; 
        constant tOH:   time := 5 ns; 
        constant tWC:   time := 45 ns; 
        constant tAW:   time := 35 ns; 
        constant tWP:   time := 30 ns; 
        constant tWHZ:  time := 20 ns; 
        constant tDW:   time := 20 ns; 
        constant tDH:   time := 0 ns;
        constant tOW:   time := 5 ns
    );
    port (
        CS_b, WE_b, OE_b:   in      std_logic;
        Address:            in      std_logic_vector(12 downto 0);
        Data:               inout   std_logic_vector(7 downto 0) := 
                                        (others => 'Z')
    ); 
	end component;
end package;
