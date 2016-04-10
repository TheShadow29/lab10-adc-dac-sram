library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;

entity Testbench is
end entity;

architecture Behave of Testbench is
  signal din,dout: std_logic_vector(7 downto 0);
  signal start, done: std_logic;
  signal clk: std_logic := '0';
  signal rst: std_logic := '1';
  signal WR, CS, RD: std_logic;
  signal INTR : std_logic := '1';

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

  function to_bit_vector(x: std_logic_vector) return bit_vector is
    alias lx: std_logic_vector(1 to x'length) is x;
    variable ret_var : bit_vector(1 to x'length);
  begin
     for I in 1 to x'length loop
        if(lx(I) = '1') then
           ret_var(I) :=  '1';
        else
           ret_var(I) :=  '0';
	end if;
     end loop;
     return(ret_var);
  end to_bit_vector;
--------------------------------------------------------------------------  
  
 signal out_clk : std_logic := '0';
 signal clk_out :std_logic;
 
begin

  clk <= not clk after 10 ns; -- assume 10ns clock.

	process(clk) 
	variable count : integer := 250;
	
	begin 
	
	if(rising_edge(clk)) then 
		count := count - 1;
		clk_out <= out_clk;
		
		if(count = 0) then 
		out_clk <= not out_clk;
		count := 250;
		else
		out_clk <= out_clk;
		end if;
	end if;
	
	end process;

  -- reset process
  process
  begin
     wait until clk_out = '1';
     rst <= '0';
     wait;
  end process;

 process 
    variable err_flag : boolean := false;
    File INFILE: text open read_mode is "infile.txt";
    FILE OUTFILE: text  open write_mode is "OUTPUTS.txt";

    ---------------------------------------------------
    -- edit the next few lines to customize
    variable A_var: bit_vector ( 7 downto 0);
    variable output_var: bit_vector ( 7 downto 0);
    ----------------------------------------------------
    variable INPUT_LINE: Line;
    variable OUTPUT_LINE: Line;
    variable LINE_COUNT: integer := 0;
    
  begin
	start <= '1';
    wait until clk_out = '1';
		   
    while not endfile(INFILE) loop 
    	  wait until clk_out = '0';

          LINE_COUNT := LINE_COUNT + 1;
	
	  readLine (INFILE, INPUT_LINE);
          read (INPUT_LINE, A_var);
	      read (INPUT_LINE, output_var);
          
	--if(WR = '0') then
	--INTR <= '0' after 218 us;
    --end if;
   
		
          --------------------------------------
          -- from input-vector to DUT inputs
	  din <= to_std_logic_vector(A_var);
	  
          --------------------------------------
		  
		
         while (true) loop
            wait until clk_out = '1';
         	start <= '0';
		 	if(WR = '0') then
				INTR <= '0' after 218 us;
				report "WR low hence INTR going low in 218" severity note;
   		 	end if;
       
         	if(done = '1') then
         		INTR <= '1';
              	exit;
          	end if;
       	 end loop;
	  
	  --start <= '1';
          --------------------------------------
	  -- check outputs.
	  if (dout /= to_std_logic_vector(output_var)) then
             write(OUTPUT_LINE,to_string("ERROR: in RESULT, line "));
             write(OUTPUT_LINE, LINE_COUNT);
             writeline(OUTFILE, OUTPUT_LINE);
                          
             err_flag := true;
          end if;
          --------------------------------------
    end loop;

    assert (err_flag) report "SUCCESS, all tests passed." severity note;
    assert (not err_flag) report "FAILURE, some tests failed." severity error;

    wait;
  end process;

  dut: ADCC port map (data_in => din, CS => CS, WR => WR, INTR => INTR, RD => RD, adc_run => start, 
		 adc_output_ready => done, adc_data => dout, clock => clk, reset => rst);

			

end Behave;
