library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

library work;
	use work.sram_package.all;

entity wtime is
	port
	(
		start : in std_logic;
		done : out std_logic;
		repeat_n : in integer;
		clk, reset : in std_logic	
	);
end entity ; -- wtime

architecture wait1 of wtime is
	signal Tvar : std_logic_vector(10 downto 0);
	signal Svar : std_logic_vector (5 downto 0);
begin
	wcp : wtime_cp 
			port map
			(
				Tv => Tvar,
				Sv => Svar,
				clk => clk,
				reset => reset,
				start => start,
				done => done
			);
	wdp : wtime_dp
			port map
			(
				Tv => Tvar,
				Sv => Svar,
				clk => clk,
				reset => reset,
				repeat_n => repeat_n
			);
end architecture ; -- wait