library ieee;
	use ieee.std_logic_1164.all;

library std;
	use std.textio.all;

--library work;
--	use work.sram_package.all;

entity tb_adcc is
end entity ; -- tb_adcc


architecture Behave of tb_adcc is
	signal	adc_run : std_logic;
	signal	adc_output_ready : std_logic;
	signal	adcc_data_in :std_logic_vector(7 downto 0);
	signal	adcc_data_out : std_logic_vector(7 downto 0);
	signal	cs_bar : std_logic;
	signal	wr_bar : std_logic;
	signal	rd_bar : std_logic;
	signal	intr_bar : std_logic;
	signal	clk : std_logic := '1';
	signal	reset : std_logic := '0';

  

  function to_string(x: string) return string is
      variable ret_val: string(1 to x'length);
      alias lx : string (1 to x'length) is x;
  	begin  
          ret_val := lx;
      return(ret_val);
  end to_string;

  function to_std_logic (x: bit) return std_logic is
  begin
	if(x = '1') then return ('1');
	else return('0'); end if;
  end to_std_logic;

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

	    File INFILE: text open read_mode is "adc_sim.txt";
	    FILE OUTFILE: text  open write_mode is "adcc_outputs.txt";

	    ---------------------------------------------------
	    -- edit the next few lines to customize
	    variable adcc_data_in_var: bit_vector (7 downto 0);
	    variable adcc_data_out_var: bit_vector (7 downto 0);
	    ----------------------------------------------------
	    variable INPUT_LINE: Line;
	    variable OUTPUT_LINE: Line;
	    variable OUTPUT_LINE2: Line;
	    variable LINE_COUNT: integer := 0;

		begin 

		    while not endfile(INFILE) loop

				intr_bar <= '1';
				assert err_flag report "kya fart hai" severity note;

				-- clock = '0', data_ins should be changed here.
				LINE_COUNT := LINE_COUNT + 1;
				readLine (INFILE, INPUT_LINE);
				read (INPUT_LINE, adcc_data_in_var);
				read (INPUT_LINE, adcc_data_out_var);

				adcc_data_in <= to_std_logic_vector(adcc_data_in_var);
				
				adc_run <= '1';
				wait for 20 ns;
				adc_run <= '0';

				wait for 300 us;
				intr_bar <= '0';
				wait until rd_bar = '1';
				intr_bar <= '1';
				wait until adc_output_ready = '1';
		 		
				if (adcc_data_out /= to_std_logic_vector(adcc_data_out_var)) then
					write(OUTPUT_LINE,to_string("ERROR: line "));
					write(OUTPUT_LINE, LINE_COUNT);
					writeline(OUTFILE, OUTPUT_LINE);
					err_flag := true;
				end if; 
			end loop;

  	  assert (err_flag) report "SUCCESS, all tests passed." severity note;
  	  assert (not err_flag) report "FAILURE, some tests failed." severity error;

			wait;
		end process;

	dut : adcc port map
			(
				adc_run => adc_run,
				adc_output_ready => adc_output_ready,
				data_in => adcc_data_in,
				adc_data => adcc_data_out,
				CS => cs_bar,
				WR => wr_bar,
				RD => rd_bar,
				INTR => intr_bar,
				clock => clk,
				reset => reset
			);
  
end Behave;
