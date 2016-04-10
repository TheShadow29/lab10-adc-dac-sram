library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

library work;
	use work.sram_package.all;

entity wtime_dp is
	port
	(
		Tv : in std_logic_vector;
		Sv : out std_logic_vector;
		clk, reset : in std_logic;
		repeat_n : in integer
	);
end entity ; -- wtime_dp

architecture data of wtime_dp is
	signal count, count_reg, count_reg_in : integer;
	signal count_en : std_logic;

	constant count_init : integer := repeat_n - 1;
begin
	Sv(0) <= '1' when (count = 0) else '0';

	count_reg_in <= (count - 1);--delayed;

	count_reg <= count_init when (Tv(0) = '1')
					else (count_reg_in) when (Tv(1) = '1');
	count_en <= Tv(0) or Tv(1);
	count_dff : data_register_int 
					port map 
					(
						Din => count_reg,
						Dout => count, 
						enable => count_en,
						clk => clk
					);
end architecture ; -- data