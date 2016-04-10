library ieee;
	use ieee.std_logic_1164.all;
library ieee;
	use ieee.numeric_std.all;
library std;
	use std.textio.all;
library work;
	use work.sram_package.all;

entity tb_smc is
end entity ; -- tb_smc

architecture testing of tb_smc is
	type sram_mem is array(8191 downto 0) of std_logic_vector(7 downto 0);

	function to_string(x: string) return string is
	  variable ret_val: string(1 to x'length);
	  alias lx : string (1 to x'length) is x;
	begin
	  ret_val := lx;
	  return(ret_val);
	end to_string;

	function to_std_logic_vector(x: bit_vector) return std_logic_vector is
	alias lx: bit_vector(1 to x'length) is x;
	variable ret_var : std_logic_vector(1 to x'length);
	begin
	 for I in 1 to x'length loop
	    if(lx(I) = '1') then
	       ret_var(I) :=  '1';
	    else
	       ret_var(I) :=  '0';
	end if;
	 end loop;
	 return(ret_var);
	end to_std_logic_vector;
	function to_std_logic (x: bit) return std_logic is
		begin
		if(x = '1') then return ('1');
		else return('0'); end if;
	end to_std_logic;
	function vec2int(vec1: bit_vector) return integer is
		variable retval: integer:=0;
		alias vec: bit_vector(vec1'length-1 downto 0) is vec1;
		begin
		for i in vec'high downto 1 loop
		  if (vec(i)='1') then
		    retval:=(retval+1)*2;
		  else
		    retval:=retval*2;
		  end if;
		end loop;
		if vec(0)='1' then
	 	 retval:=retval+1;
		end if;
		return retval;
	end vec2int;

	signal mc_start : std_logic;
	signal mc_write : std_logic;
	signal addr : std_logic_vector (12 downto 0);
	signal out_addr : std_logic_vector(12 downto 0);
	signal mc_writedata : std_logic_vector (7 downto 0);
	signal mc_readdata : std_logic_vector(7 downto 0);
	signal data_rw : std_logic_vector(7 downto 0) := (others => 'Z');
	signal we_bar, cs_bar, oe_bar : std_logic;
	signal clk, reset : std_logic := '1';
	signal mc_done : std_logic;

begin
	clk <= not clk after 10 ns;

	process
		begin
			wait until clk = '1';
			reset <= '0';
			wait;
		end process;

	process
		variable err_flag : boolean := false;
		File INFILE: text open read_mode is "smcc_tracefile.txt";
		FILE OUTFILE: text  open write_mode is "OUTPUTS_SMC.txt";

		---------------------------------------------------
		-- edit the next few lines to customize
		variable rw_bit: bit;
		variable address_bv: bit_vector (12 downto 0);
		variable data_rw_bv: bit_vector (7 downto 0);
		variable ram: sram_mem;
		----------------------------------------------------
		variable INPUT_LINE: Line;
		variable OUTPUT_LINE: Line;
		variable LINE_COUNT: integer := 0;
		
		begin

		wait until clk = '1';

		while not endfile(INFILE) loop
			assert false report "chal ja plz" severity note;
			wait until clk = '0';
			LINE_COUNT := LINE_COUNT + 1;

			readLine (INFILE, INPUT_LINE);
			read (INPUT_LINE, rw_bit);
			read (INPUT_LINE, address_bv);
			read (INPUT_LINE, data_rw_bv);
			
			--if (rw_bit = '1') then
			--	ram(vec2int(address_bv)) := data_rw;
			--end if;

			--start
			addr <= to_std_logic_vector(address_bv);
			mc_start <= '1';


			mc_write <= to_std_logic(rw_bit);

			wait until clk = '1';
			mc_start <= '0';
			if (mc_write = '1') then
				mc_writedata <= to_std_logic_vector(data_rw_bv);
				wait until mc_done = '1';
				ram(vec2int(address_bv)) := data_rw;
			else
				wait until oe_bar = '0';
				data_rw <= ram(vec2int(address_bv)) after 45 ns;
				wait until mc_done = '1';
				if (mc_write = '0') then
					--for I in 7 downto 0 loop
					--	assert false report " "& std_logic'image(mc_readdata(I)) severity note;
					--end loop;
					if (mc_readdata /= to_std_logic_vector(data_rw_bv)) then

						assert false report "fart at "& integer'image(LINE_COUNT) severity error;
						write(OUTPUT_LINE,to_string("ERROR: in RESULT, line "));
						write(OUTPUT_LINE, LINE_COUNT);
						write(OUTPUT_LINE, to_string("your output "));
						for I in 7 downto 0 loop
							write(OUTPUT_LINE, to_bit(data_rw(I)));
						end loop;
						write(OUTPUT_LINE, to_string(" expected output "));  
						write(OUTPUT_LINE, data_rw_bv(7 downto 0));    
						writeline(OUTFILE, OUTPUT_LINE);
						err_flag := true;
					end if;
				end if;
			end if;

		end loop;

		assert (err_flag) report "SUCCESS, all tests passed." severity note;
		assert (not err_flag) report "FAILURE, some tests failed." severity error;

		wait;
	end process;
	dut : smc port map 
	(
		mc_start => mc_start,
		mc_write => mc_write, 
		addr => addr,
		out_addr => out_addr,
		mc_writedata => mc_writedata,
		mc_readdata => mc_readdata,
		data_rw => data_rw,
		we_bar => we_bar, 
		cs_bar => cs_bar,
		oe_bar => oe_bar,
		clk => clk,
		reset => reset,
		mc_done => mc_done
	);

end architecture ; -- testing