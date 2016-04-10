---data_register_bin.vhd
library ieee;
use ieee.std_logic_1164.all;

library work;
  use work.sram_package.all;

entity data_register_bin is
	port (Din: in std_logic;
	      Dout: out std_logic;
	      clk, enable: in std_logic);
end entity;
architecture Behave of data_register_bin is
begin
    process(clk)
    begin
       if(clk'event and (clk  = '1')) then
           if(enable = '1') then
               Dout <= Din;
           end if;
       end if;
    end process;
end Behave;
