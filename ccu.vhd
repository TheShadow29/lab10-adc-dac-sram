library ieee;
use ieee.std_logic_1164.all;

entity Adder13 is 
   port (A, B: in std_logic_vector(12 downto 0); ---------------asuming a > b  -------------
   		 RESULT: out std_logic_vector(12 downto 0));
end entity;

architecture behave of Adder13 is
begin
   process(A,B)
     variable carry: std_logic;
   begin
     carry := '0';
     for I in 0 to 12 loop
        RESULT(I) <= (A(I) xor B(I)) xor carry;
        carry := (carry and (A(I) or B(I))) or (A(I) and B(I));
     end loop;
   end process;
end behave;
------------------------------------------------------------------------

library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity CCU is
	port
	(
		-------Outside world interface
		capture : in std_logic;
		display : in std_logic;
		to_dac : out std_logic_vector (7 downto 0);
		-------ADCC interface
		adc_run : out std_logic;
		adc_output_ready : in std_logic;
		adc_data : in std_logic_vector(7 downto 0);
		-------SMC interface
		mc_start : out std_logic;
		mc_write : out std_logic;
		mc_done : in  std_logic;
		address : out std_logic_vector (12 downto 0);
		mc_write_data : out std_logic_vector (7 downto 0);
		mc_read_data : in std_logic_vector (7 downto 0);
		
		clk, reset : in std_logic
	);
end entity ; 

architecture logic of CCU is
	signal addr, addr_in : std_logic_vector(12 downto 0) := (others => '0');
	signal new_addr: std_logic_vector(12 downto 0);
	signal adc_data_in: std_logic_vector(7 downto 0);
	signal cs,wr,rd,intr,mc_start,mc_write,we_bar,cs_bar,oe_bar,mc_done: std_logic;
	constant c_one : std_logic_vector(12 downto 0) := "0000000000001";
	signal addr_en, dac_en : std_logic := '0';

--process
--begin
	--variable count: integer := 0;
	--if(adc_output_ready = '1' or capture = '1') then
		--count := count + 1;
	--else
		--count := count;
	--end if;
	
	--if(count = 8192) then
		--count := 0;
	--end if;
	
	--address_input <= to_std_logic(count, address_input'length);
	
--end process;	


	component DataRegister is
	generic (data_width:integer);
	port (Din: in std_logic_vector(data_width-1 downto 0);
	      Dout: out std_logic_vector(data_width-1 downto 0);
	      clk, enable: in std_logic);
	end component;


begin

	----------------Address Register
	addr_en <= (display and mc_done) or (capture and adc_output_ready); 
	address_reg : DataRegister
					generic map (data_width => 13)
					port map 
					(
						Din => addr_in,
						Dout => addr, 
						enable => addr_en,
						clk => clk
					);
			
	---------------Address Increment	
	addr_in <= c_one when (reset = '1') else new_addr;	
	add : Adder13 
			port map (
						A => addr, 
						B => c_one, 
						RESULT => new_addr
					 );
					 
	--------------ADC to SRAM data transfer register
	tran_reg_adc : DataRegister 
				generic map (data_width => 8)
				port map
				(
					Din => adc_data,
					Dout => mc_write_data,
					enable => adc_output_ready,
					clk => clk
				);	
				
	--------------SRAM to DAC data transfer register
	dac_en <= (not capture) and (mc_done and display);
	tran_reg_dac : DataRegister
					generic map (data_width => 8)
					port map
					(
						Din => mc_read_data,
						Dout => to_dac,
						enable => dac_en,
						clk => clk
					);
						
	--------------Control signals
	adc_run <= capture;
	mc_start <= adc_output_ready or capture;
	mc_write <= '1' when (adc_output_ready='1') else '0';
	address <= addr;

	--add smc port map
	smc_inst: smc port map (

	--add adcc port map 
	adcc_inst: ADCC port map (
	
end architecture logic;
