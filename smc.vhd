library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

library work;
	use work.sram_package.all;

entity smc is
	port
	(
		mc_start : in std_logic;
		mc_write : in std_logic;
		addr : in std_logic_vector (12 downto 0);
		out_addr : out std_logic_vector(12 downto 0);
		mc_writedata : in std_logic_vector (7 downto 0);
		mc_readdata : out std_logic_vector(7 downto 0);
		data_rw : inout std_logic_vector(7 downto 0) := (others => 'Z');
		we_bar, cs_bar, oe_bar : out std_logic;
		clk, reset : in std_logic;
		mc_done : out std_logic
	);
end entity ; -- smc

architecture logic of smc is
	type FsmState is (rst, read_state, read_wt1, read_data, read_wt2, read_done_state,
					write_state, write_wt1, write_data, write_wt2, write_done_state);
	
	signal curr_state : FsmState;

	signal mc_readdata_reg : std_logic_vector(7 downto 0);
	signal mc_writedata_reg : std_logic_vector(7 downto 0);

	signal mc_done_reg : std_logic;

	signal start_reading : std_logic;
	signal start_writing : std_logic;

	signal counter_high : std_logic;

	signal st_wt : std_logic_vector(10 downto 0) := (others => '0');
	signal do_wt : std_logic_vector(10 downto 0) := (others => '0');
	constant highZ8 : std_logic_vector(7 downto 0) := (others => 'Z');
	signal make_data_rw_high : std_logic := '0';

begin

	--------------------
	------wait_logic----
	--------------------

	--wait for 2-3 cycles before making cs_bar low (read)
	wait0 : wtime port map (start => st_wt(0), done => do_wt(0), repeat_n => 3, clk => clk, reset => reset);
	--wait for 2-3 cycles before making cs_bar low (write)
	wait1 : wtime port map (start => st_wt(1), done => do_wt(1), repeat_n => 3, clk => clk, reset => reset);
	--wait for 2-3 cycles before making oe_bar low (read)
	wait2 : wtime port map (start => st_wt(2), done => do_wt(2), repeat_n => 3, clk => clk, reset => reset);
	--wait for 15 cycles before reading the data (read)
	wait3 : wtime port map (start => st_wt(3), done => do_wt(3), repeat_n => 15, clk => clk, reset => reset);
	--wait for 2-3 cycles before making cs_bar and oe_bar high (read)
	wait4 : wtime port map (start => st_wt(4), done => do_wt(4), repeat_n => 3, clk => clk, reset => reset);
	--wait for 2-3 cycles before making we_bar low (write)
	wait5 : wtime port map (start => st_wt(5), done => do_wt(5), repeat_n => 3, clk => clk, reset => reset);
	--wait for 20 cycles before reading the data (read)
	wait6 : wtime port map (start => st_wt(6), done => do_wt(6), repeat_n => 20, clk => clk, reset => reset);
	--wait for 2-3 cycles before making cs_bar and we_bar high (write)
	wait7 : wtime port map (start => st_wt(7), done => do_wt(7), repeat_n => 3, clk => clk, reset => reset);

	----counter for 1khz frequency
	count1 : wtime port map (start => '1', done => counter_high, repeat_n => 50000, clk => clk, reset => reset);

	mc_done <= counter_high and mc_done_reg;

	----------------------------
	-------data_transfer_logic--
	----------------------------
	data_read : data_register 
				generic map (data_width => 8)
				port map 
				(
					Din => data_rw,
					Dout => mc_readdata,
					enable => start_reading,
					clk => clk
				);
	--data_rw <= mc_writedata when (start_writing = '1') else highZ8;
	--mc_writedata_reg <= mc_writedata when (start_writing = '1') else highZ8;
	mc_writedata_reg <=  highZ8 when (make_data_rw_high = '1')
						else mc_writedata when (start_writing = '1')
						else highZ8;
	data_write : data_register 
				generic map (data_width => 8)
				port map 
				(
					Din => mc_writedata_reg,
					Dout => data_rw,
					enable => '1',
					clk => clk
				);

	-------------------------------
	-------address transfer logic--
	-------------------------------
	address_transfer : data_register 
				generic map (data_width => 13)
				port map 
				(
					Din => addr,
					Dout => out_addr,
					enable => '1',
					clk => clk
				);

	--------------------
	----fsm_logic-------
	--------------------
	p1 : 
		process(clk, reset, mc_start, curr_state)
			
			variable next_state : FsmState;
			variable done_var : std_logic;

			variable cs_bar_var : std_logic;
			variable oe_bar_var : std_logic;
			variable we_bar_var : std_logic;

			variable start_reading_var : std_logic;
			variable start_writing_var : std_logic;

			variable make_data_rw_high_var : std_logic;
			
			variable st_wt_var : std_logic_vector(10 downto 0) := (others => '0');

			variable data_rw_in_var : std_logic_vector(7 downto 0) := highZ8;
			variable mc_readdata_var : std_logic_vector(7 downto 0) := highZ8;

			begin

				next_state := curr_state;

				case curr_state is
					
					when rst =>
						cs_bar_var := '1';
						oe_bar_var := '1';
						we_bar_var := '1';
						if (mc_start = '1') then
							start_reading_var := '0';
							start_writing_var := '0';
							if (mc_write = '0') then
								next_state := read_state;
								st_wt_var(0) := '1'; 
							else
								st_wt_var(1) := '1'; 
								next_state := write_state;
							end if;
						end if;

					when read_state =>
						if (do_wt(0) = '1') then
							st_wt_var(0) := '0';
							st_wt_var(2) := '1'; 
							cs_bar_var := '0';
							next_state := read_wt1;
						else
							next_state := read_state;
						end if;

					when read_wt1 =>
						if(do_wt(2) = '1') then
							st_wt_var(2) := '0';
							st_wt_var(3) := '1';
							oe_bar_var := '0';
							next_state := read_data;
						else 
							next_state := read_wt1;
						end if;

					when read_data =>
						if (do_wt(3) = '1') then
							st_wt_var(3) := '0';
							start_reading_var := '1';
							st_wt_var(4) := '1';
							next_state := read_wt2;
						else
							next_state := read_data;
						end if;

					when read_wt2 =>
						if (do_wt(4) = '1') then
							st_wt_var(4) := '0';
							cs_bar_var := '1';
							oe_bar_var := '1';
							next_state := read_done_state;
						else
							next_state := read_wt2;
						end if;

					when read_done_state =>
						done_var := '1';
						next_state := rst;

					when write_state =>
						if (do_wt(1) = '1') then
							st_wt_var(1) := '0';
							cs_bar_var := '0';
							st_wt_var(5) := '1';
							next_state := write_wt1;
						else 
							next_state := write_state;
						end if;

					when write_wt1 =>
						if (do_wt(5) = '1') then
							st_wt_var(5) := '0';
							we_bar_var := '0';
							st_wt_var(6) := '1';
							next_state := write_data;
						else
							next_state := write_wt1;
						end if;

					when write_data =>
						if (do_wt(6) = '1') then
							st_wt_var(6) := '0';
							start_writing_var := '1';
							st_wt_var(7) := '1';
							next_state := write_wt2;
						else
							next_state := write_data;
						end if;

					when write_wt2 => 
						if (do_wt(7) = '1') then
							cs_bar_var := '1';
							we_bar_var := '1';
							st_wt_var(7) := '0';
							next_state := write_done_state;
						else
							next_state := write_wt2;
						end if;

					when write_done_state =>
						done_var := '1';
						next_state := rst;							

				end case;

				if(clk'event and (clk = '1')) then
					if(reset = '1') then
						curr_state <= rst;
					else
						curr_state <= next_state;
					end if;
				end if;

				cs_bar <= cs_bar_var;
				oe_bar <= oe_bar_var;
				we_bar <= we_bar_var;

				st_wt <= st_wt_var;

				start_reading <= start_reading_var;
				start_writing <= start_writing_var;

				--mc_readdata_reg <= mc_readdata_var;

				make_data_rw_high <= make_data_rw_high_var;

				mc_done_reg <= done_var;
			end process ; -- p1

end architecture ; -- logic