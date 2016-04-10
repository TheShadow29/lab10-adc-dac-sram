library ieee;
use ieee.std_logic_1164.all;

library work;
  use work.sram_package.all;

entity adder13 is
	port 
	(
		A, B : in std_logic_vector(12 downto 0);
		Result : out std_logic_vector(12 downto 0)
	);
end entity;

architecture serial of adder13 is

begin
	process (A, B)
		variable carry : std_logic;
		begin
			carry := '0';
			for I in 0 to 12 loop
				Result(I) <= A(I) xor B(I) xor carry;
				carry := (carry and (A(I) or B(I))) or (A(I) and B(I));
			end loop;
		end process;
end architecture ; -- serial