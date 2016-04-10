library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

library work;
	use work.sram_package.all;

entity adcc is
	port
	(
		adc_run : in std_logic;
		adc_output_ready : out std_logic;
		adcc_data_in : in std_logic_vector(7 downto 0);
		adcc_data_out : out std_logic_vector(7 downto 0);
		cs_bar : out std_logic;
		wr_bar : out std_logic;
		rd_bar : out std_logic;
		intr_bar : in std_logic;
		clk : in std_logic;
		reset : in std_logic
	);
end entity ; -- adcc

architecture main_logic of adcc is
	type FsmState is (rst, write_state, wait_state1, wait_state2, read_state, done_state);
	signal curr_state : FsmState;

	signal st_wt : std_logic_vector(5 downto 0) := (others => '0');
	signal do_wt : std_logic_vector(5 downto 0);

	--signal intr_bar_stable : std_logic;

	signal start_reading : std_logic := '0';

	signal counter_high : std_logic := '0';

	signal done_data_transfer : std_logic := '0';
begin

	--------------------
	----fsm_logic-------
	--------------------
	p1 : process(clk, reset, adc_run, curr_state)
			variable next_state : FsmState;
			variable done_var : std_logic;
			variable cs_bar_var : std_logic := '1';
			variable rd_bar_var : std_logic := '1';
			variable wr_bar_var : std_logic := '1';

			variable start_reading_var : std_logic := '0';
			
			variable st_wt_var : std_logic_vector (5 downto 0) := (others => '0');
			begin

				next_state := curr_state;

				case curr_state is
					when rst =>
						cs_bar_var := '1';
						rd_bar_var := '1';
						wr_bar_var := '1';
						if (adc_run = '1') then
							next_state := write_state;
							done_var := '0';
							start_reading_var := '0';
							cs_bar_var := '0';
							st_wt_var(0) := '1';
						else 
							next_state := rst;
						end if;

					when write_state =>
						--st_wt_var(5) := '1';
						if (do_wt(0) = '1') then
							st_wt_var(0) := '0';
							wr_bar_var := '0';
							st_wt_var(1) := '1';
							next_state := wait_state1;
						else 
							next_state := write_state;
						end if;

					when wait_state1 => 
						if (do_wt(1) = '1') then
							st_wt_var(1) := '0';
							wr_bar_var := '1';
							next_state := wait_state2;
						else 
							next_state := wait_state1;
						end if;

					when wait_state2 => 
						if (intr_bar = '0') then
							next_state := read_state;
							st_wt_var(2) := '1';
						else
							next_state := wait_state2;
						end if;

					when read_state =>
						if (do_wt(2) = '1') then 
							rd_bar_var := '0';
							st_wt_var(2) := '0';
							st_wt_var(3) := '1'; 
							start_reading_var := '1';
							next_state := done_state;
						else
							next_state := read_state;
						end if;

					when done_state =>
						if (do_wt(3) = '1') then
							done_var := '1';
							st_wt_var(3) := '0';
							next_state := rst;
						else
							next_state := done_state;
						end if;

				end case;

				if(clk'event and (clk = '1')) then
					if(reset = '1') then
						curr_state <= rst;
					else
						curr_state <= next_state;
					end if;
				end if;
				--if (reset = '0')then
				--	curr_state <= next_state;
				--else
				--	curr_state <= rst;
				--end if;
						

				cs_bar <= cs_bar_var;
				rd_bar <= rd_bar_var;
				wr_bar <= wr_bar_var;

				st_wt <= st_wt_var;

				start_reading <= start_reading_var;

				done_data_transfer <= done_var;

			
			end process ; -- identifier
	--------------------
	------wait_logic----
	--------------------

	--wait for 2-3 cycles before making wr_bar low
	wait0 : wtime port map (start => st_wt(0), done => do_wt(0), repeat_n => 3, clk => clk, reset => reset);

	--wait for 200ns before making wr_bar high
	wait1 : wtime port map (start=> st_wt(1), done => do_wt(1), repeat_n => 6, clk => clk, reset => reset);

	--wait for 2-3 cycles before making rd_bar_low
	wait2 : wtime port map (start => st_wt(2), done => do_wt(2), repeat_n => 3, clk => clk, reset => reset);

	--wait for 200ns before making rd_bar high
	wait3 : wtime port map (start => st_wt(3), done => do_wt(3) , repeat_n => 6, clk => clk, reset => reset);

	----counter for 1khz frequency
	count1 : wtime port map (start => '1', done => counter_high, repeat_n => 50000, clk => clk, reset => reset);

	----------------------------
	-------data_transfer_logic--
	----------------------------
	data_t : data_register 
				generic map (data_width => 8)
				port map 
				(
					Din => adcc_data_in,
					Dout => adcc_data_out,
					enable => start_reading,
					clk => clk
				);
	----------------------------
	-------intr_stable----------
	----------------------------

	--p0 : process (clk)
	--		begin
	--       		if (clk'event and (clk  = '1')) then
	--           		if (reset = '1') then
	--               			intr_bar_stable <= intr_bar;
	--           		end if;
	--       		end if;
	--    	end process;

	----------------------------
	----------done_logic--------
	----------------------------
	
	adc_output_ready <= done_data_transfer and counter_high;


end architecture ; -- main_logic