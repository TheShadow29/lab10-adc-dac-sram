library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

library work;
	use work.sram_package.all;

entity ccu is
	port
	(
		capture : in std_logic;
		display : in std_logic;
		adc_run : out std_logic;
		adc_output_ready : in std_logic;
		adc_data : in std_logic_vector(7 downto 0);
		start_c : out std_logic;
		write_c : out std_logic;
		done_c : in  std_logic;
		address : out std_logic_vector (12 downto 0);
		write_data : out std_logic_vector (7 downto 0);
		read_data : in std_logic_vector (7 downto 0);
		to_dac : out std_logic_vector (7 downto 0);
		clk, reset : in std_logic
	);
end entity ; -- ccu

architecture logic of ccu is
	signal address_input : std_logic_vector(12 downto 0) := (others => '0');
begin

	address_dff : data_register
					generic map (data_width => 13)
					port map 
					(
						Din => address_input,
						Dout => address, 
						enable => address_en,
						clk => clk
					);

	adc_run <= capture;
	mc_start <= adc_output_ready or capture;
	mc_write <= '1' when (adc_output_ready='1') else '0';

	--add smc port map

	--add adcc port map 
	
end architecture ; -- logic