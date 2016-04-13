-------------------------------DATA REGISTER---------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataRegister is
	generic (data_width:integer);
	port (Din: in std_logic_vector(data_width-1 downto 0);
	      Dout: out std_logic_vector(data_width-1 downto 0);
	      clk, enable: in std_logic);
end entity DataRegister;

architecture Behave of DataRegister is
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataRegister_Bit is
	port (Din: in std_logic;
	      Dout: out std_logic;
	      clk, enable: in std_logic);
end entity DataRegister_Bit;

architecture Behave of DataRegister_Bit is
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

-------------------------------------------------------------------------------


-----------------------------CONTROL PATH--------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ADC_ControlPath is 
port ( 	 adc_run : in std_logic;
		 adc_output_ready : out std_logic;
		 ------- CP - DP interface
		 S : in std_logic;
		 T0, T1, T2, T3, T4, T5, T6, T7 : out std_logic;
		 clock, reset : in std_logic );
end entity;

architecture ADC_Control of ADC_ControlPath is
	type FsmState is (s_rst, s0, s1, s2, s3, s4, s5, s_done);
	signal q: FsmState;
	
	signal myClk: std_logic;
	signal reducedClk: std_logic := '0';
	
begin
	
process(clock) 
	variable count: integer := 500;
	begin 	
	if(rising_edge(clock)) then 
	
		myClk <= reducedClk;
		count := count - 1;
		
		if(count = 0) then 
			reducedClk <= (not reducedClk); --toggle at every 500th rising edge
			count := 500;
		else 
			reducedClk <= reducedClk;
		end if;
		
	end if;
end process;

process (adc_run, q, S, myClk, reset)
	variable nq: FsmState := q;
	variable Tvar: std_logic_vector (7 downto 0);
	variable out_var: std_logic;
begin
    Tvar := (others => '0');
    out_var := '0';
    nq := q;
    
	case q is
		when s_rst =>
			--CS <= '1';
			Tvar(1) := '1';
			if(adc_run = '1') then
				nq := s0;
			end if;
			
		when s0 =>
			--CS <= '1';
			Tvar(1) := '1';
			nq := s1;
			
		when s1 =>
			--CS <= '0';
			Tvar(0) := '1';
			nq := s2;
			
		when s2 =>
			--WR <= '0';
			Tvar(3) := '1';
			nq := s3;
				
		when s3 =>
			--WR <= '1';
			Tvar(2) := '1';
			nq := s4;
			
		when s4 =>
			if ( S='0') then --if (falling_edge(INTR))
				--RD <= '0';
				Tvar(5) := '1';
				-- adc_data <= data_in;
				Tvar(6) := '1';
				nq := s5;
			else
				nq := s4;
			end if;
				
		when s5 =>
			--RD <= '1';
			Tvar(4) := '1';
			nq := s_done;
			
		when s_done =>
			out_var := '1';
			Tvar(7) := '1';
			nq := s0;
			
		when others =>
			nq := s0;
			
			----------remove latches
			
	end case;
	
	T0 <= Tvar(0); T1 <= Tvar(1); T2 <= Tvar(2); T3 <= Tvar(3); T4 <= Tvar(4);
	T5 <= Tvar(5); T6 <= Tvar(6); T7 <= Tvar(7); 
	
	if(myClk'event and myClk = '1') then
     if(reset = '1') then
       q <= s_rst;
     else
       q <= nq;
       adc_output_ready <= out_var;
     end if;
   end if;
         
end process;
end ADC_Control;
--------------------------------------------------------------------------------

--------------------------------DATA PATH--------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ADC_DataPath is
port(	S : out std_logic;
		CS, WR, RD : out std_logic;
		INTR : in std_logic;
		T0,T1,T2,T3,T4,T5,T6,T7 : in std_logic;
		data_in : in std_logic_vector(7 downto 0);
		data_out : out std_logic_vector(7 downto 0);
		clock, reset : in std_logic );
end entity;

architecture ADC_DataP of ADC_DataPath is

	signal inreg,outreg : std_logic_vector(7 downto 0);	
	signal CS_en,WR_en,RD_en,inreg_en,outreg_en : std_logic;
	signal CS_in,WR_in,RD_in : std_logic;
	signal myClk : std_logic;
	signal reducedClk : std_logic := '0';	
	
	
	component DataRegister is
	generic (data_width:integer);
	port (Din: in std_logic_vector(data_width-1 downto 0);
	      Dout: out std_logic_vector(data_width-1 downto 0);
	      clk, enable: in std_logic);
	end component;
	
	component DataRegister_Bit is
	port (Din: in std_logic;
	      Dout: out std_logic;
	      clk, enable: in std_logic);
	end component;
		
begin
	
process(clock) 
	variable count: integer := 500;
	begin 	
	if(rising_edge(clock)) then 
	
		count := count - 1;
		myClk <= reducedClk;
		
		if(count = 0) then 
			reducedClk <= (not reducedClk); --toggle at every 500th rising edge
			count := 500;
		else 
			reducedClk <= reducedClk;
		end if;
		
	end if;
end process;

    -- predicate
    intr_reg: DataRegister_Bit
    	  port map (Din => INTR, Dout => S, enable => '1', clk => myClk);
    	  
    -- CS
    CS_en <= T0 or T1;
    CS_in <= '0' when T0='1' else '1';
    cs_reg: DataRegister_Bit
    	  port map (Din => CS_in, Dout => CS, enable => CS_en, clk => myClk);
	
	-- WR
	WR_en <= T2 or T3;
    WR_in <= '1' when T2='1' else '0';
    wr_reg: DataRegister_Bit
    	  port map (Din => WR_in, Dout => WR, enable => WR_en, clk => myClk);
    
    -- RD
    RD_en <= T4 or T5;
    RD_in <= '1' when T4='1' else '0';
    rd_reg: DataRegister_Bit
    	  port map (Din => RD_in, Dout => RD, enable => RD_en, clk => myClk);
	
	-- outreg
	inreg_en <= T6;
	inreg <= data_in when T6='1' else "00000000";
    in_reg: DataRegister
    	  generic map (data_width => 8)
    	  port map (Din => inreg, Dout => outreg, enable => inreg_en, clk => myClk);
	
	-- data_out
	outreg_en <= T7;
    out_reg: DataRegister
    	  generic map (data_width => 8)
    	  port map (Din => outreg, Dout => data_out, enable => outreg_en, clk => myClk);
	
	
end ADC_DataP;
------------------------------------------------------------------------------------------------


--------------------------------------ADCC------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ADCC is 
port ( ------- ADC interface
		 data_in : in std_logic_vector(7 downto 0);
		 CS, WR, RD : out std_logic;
		 INTR : in std_logic;
		 ------- CCU interface
		 adc_run : in std_logic;
		 adc_output_ready : out std_logic;
		 adc_data : out std_logic_vector(7 downto 0);
		 clock, reset : in std_logic );
end entity;

architecture Behave of ADCC is 

	signal T0, T1, T2, T3, T4, T5, T6, T7, S : std_logic;
	
	component ADC_ControlPath is 
	port ( 	 adc_run : in std_logic;
		 adc_output_ready : out std_logic;
		 ------- CP - DP interface
		 S : in std_logic;
		 T0, T1, T2, T3, T4, T5, T6, T7 : out std_logic;
		 clock, reset : in std_logic );
	end component;
	
	component ADC_DataPath is
	port(	S : out std_logic;
		CS, WR, RD : out std_logic;
		INTR : in std_logic;
		T0,T1,T2,T3,T4,T5,T6,T7 : in std_logic;
		data_in : in std_logic_vector(7 downto 0);
		data_out : out std_logic_vector(7 downto 0);
		clock, reset : in std_logic );
	end component;
	
begin

	cp: ADC_ControlPath port map (adc_run=>adc_run,adc_output_ready=>adc_output_ready,
								  S=>S,T0=>T0,T1=>T1,T2=>T2,T3=>T3,T4=>T4,T5=>T5,T6=>T6,T7=>T7,
								  clock=>clock,reset=>reset);
								  
	dp: ADC_DataPath port map (CS=>CS,WR=>WR,RD=>RD,INTR=>INTR,
							   S=>S,T0=>T0,T1=>T1,T2=>T2,T3=>T3,T4=>T4,T5=>T5,T6=>T6,T7=>T7,
							   data_in=>data_in,data_out=>adc_data,clock=>clock,reset=>reset);
	
end Behave;
---------------------------------------------------------------------------------------------------------------

		
			
		
			
		
