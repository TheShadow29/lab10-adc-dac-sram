library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

library work;
	use work.sram_package.all;

entity wtime_cp is
	port
	(
		Tv : out std_logic_vector;
		Sv : in std_logic_vector;
		clk, reset : std_logic;
		start : in std_logic;
		done : out std_logic 
	);
end entity ; -- wtime_cp

architecture control of wtime_cp is
	type FsmState is (rst, check);
	signal curr_state : FsmState;
begin
	process (clk, reset, Sv, curr_state, start)
		variable next_state : FsmState;
		variable Tvar : std_logic_vector(10 downto 0);
		variable done_var : std_logic;
		begin
			next_state := curr_state;
			Tvar := (others => '0');
			done_var := '0';

			case curr_state is
				when rst =>
					if (start = '1') then
						Tvar(0) := '1';
						next_state := check;
					end if;
				when check =>
					if(Sv(0) = '1') then
		  				Tvar(0) := '1';
					    done_var:='1';
						next_state:=check;
	      			else Tvar(1) := '1';
               		end if;
			end case;
			Tv <= Tvar;
			done <= done_var;
  
			if(clk'event and (clk = '1')) then
				if(reset = '1') then
					curr_state <= rst;
				else
					curr_state <= next_state;
				end if;
			end if;
		end process;
end architecture ; -- control