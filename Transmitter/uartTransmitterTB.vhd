-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			         UART Transmitter TestBench			   	      -------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity uartTransmitterTB is
end entity uartTransmitterTB;

architecture sim of uartTransmitterTB is	

	-- Constants -- 
	constant c_CLK_PERIOD : time := 20 ns; -- 50 MHz clock
	constant c_CLKS_PER_BIT : integer := 434; -- 50MHz/115,200 baud rate = 434
	constant c_BIT_PERIOD : time := 8680 ns; -- 1/115,200 baud rate = 8680 ns
	

	-- Signals --
	
	-- Stimulus signals --
	signal i_clk        : std_logic;
	signal i_Data_Valid : std_logic;
	signal i_Data       : std_logic_vector(7 downto 0);
	
	-- Observed signal --
	signal w_Tx_Serial : std_logic;
	signal w_Tx_Active : std_logic;
	signal w_Tx_Done   : std_logic;
	
	signal w_UART_Data_In : std_logic;
	signal w_PB           : std_logic;
	signal w_PB_error     : std_logic;
	signal w_Rx_DV        : std_logic;
	signal w_Rx_Byte      : std_logic_vector(7 downto 0);
	
begin     
	--------- Unit Under Test port map ---------
	UUT : entity work.uartTransmitter(rtl)
	generic map (g_CLKS_PER_BIT => c_CLKS_PER_BIT) -- g_CLKS_PER_BIT for 115,200 baud rate
	port map (
			i_clk 		   => i_clk ,
			SW(7 downto 0) => i_Data ,
			SW(8) 		   => '0',
			SW(9) 		   => i_Data_Valid,
			UART_TXD       => w_Tx_Serial,
			o_Tx_Active    => w_Tx_Active,
			o_Tx_Done	   => w_Tx_Done);
	---------------------------------------------	
	
	
	--------- Instance of UART Receiver to check the UUT -------
	uart_rx : entity work.uartReceiver
	generic map(g_CLKS_PER_BIT => c_CLKS_PER_BIT) -- g_CLKS_PER_BIT for 115,200 baud rate
	port map (
			i_clk  			 => i_clk ,
			UART_RXD  		 => w_UART_Data_In ,
			o_PB            => w_PB,
			LEDR(0)         => w_PB_error ,
			o_Rx_Data_Valid => w_Rx_DV ,
			o_Rx_Byte		 => w_Rx_Byte);
	------------------------------------------------------------
	
	-- Drive UART line high (IDLE) when transmitter is not active --
	w_UART_Data_In <= w_Tx_Serial when w_Tx_Active = '1' else '1';
	
	
	-- Testbench process --
	p_TB : process
	begin
		-- Test Procedure --
		
		-- Sending data through UART only once --
		
	   i_Data 		 <= X"37";
	   i_Data_Valid <= '1';
      wait until rising_edge(i_clk);
      i_Data_Valid   <= '0';
      
      -- Check if the data arrived correctly --
		
      wait until rising_edge(w_Rx_DV); -- Data is valid
		if (w_Rx_Byte = X"37") then
			report "Test Passed - Correct Byte Received" severity Note;
			
		else
			report "Test Failed - Incorrect Byte Received" severity Note;
			
		end if;		
		
		assert false report "Tests Complete" severity failure;

	wait;
	end process p_TB;
	
	
	-- 50 MHz clock in duty cycle of 50% - 20 ns --
	p_clock : process 
	begin 
		i_clk <= '0'; wait for c_CLK_PERIOD/2; -- 10 ns
		i_clk <= '1'; wait for c_CLK_PERIOD/2; -- 10 ns
	end process p_clock;
	
end architecture sim;