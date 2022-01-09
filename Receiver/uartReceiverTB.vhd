-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			         UART Receiver TestBench			   	      -------
-----------------------------------------------------------------------------
-------          Simulate transmitted byte to the receiver            -------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartReceiverTB is
end entity uartReceiverTB;


architecture sim of uartReceiverTB is
	-- Functions --
	
	-- Displays the 4 bit binray counter on the 7 segments
	function stdLogicVectorToHexString (value:std_logic_vector(7 downto 0)) return string is
		variable hex_string : string (3 downto 1);
		begin
			-- Convert the high nibble to Hexadecimal String --
			case (value(7 downto 4)) is
				when X"0" => hex_string(3) := '0'; -- 0
				when X"1" => hex_string(3) := '1'; -- 1
				when X"2" => hex_string(3) := '2'; -- 2
				when X"3" => hex_string(3) := '3'; -- 3
				when X"4" => hex_string(3) := '4'; -- 4
				when X"5" => hex_string(3) := '5'; -- 5
				when X"6" => hex_string(3) := '6'; -- 6
				when x"7" => hex_string(3) := '7'; -- 7
				when x"8" => hex_string(3) := '8'; -- 8
				when x"9" => hex_string(3) := '9'; -- 9
				when x"A" => hex_string(3) := 'A'; -- A
				when x"B" => hex_string(3) := 'B'; -- B
				when x"C" => hex_string(3) := 'C'; -- C
				when x"D" => hex_string(3) := 'D'; -- D
				when x"E" => hex_string(3) := 'E'; -- E
				when x"F" => hex_string(3) := 'F'; -- F
			   when others => hex_string(3) := 'X'; -- X
			end case;
			
			-- Convert the low nibble to Hexadecimal String --
			case (value(3 downto 0)) is
				when X"0" => hex_string(2) := '0'; -- 0
				when X"1" => hex_string(2) := '1'; -- 1
				when X"2" => hex_string(2) := '2'; -- 2
				when X"3" => hex_string(2) := '3'; -- 3
				when X"4" => hex_string(2) := '4'; -- 4
				when X"5" => hex_string(2) := '5'; -- 5
				when X"6" => hex_string(2) := '6'; -- 6
				when x"7" => hex_string(2) := '7'; -- 7
				when x"8" => hex_string(2) := '8'; -- 8
				when x"9" => hex_string(2) := '9'; -- 9
				when x"A" => hex_string(2) := 'A'; -- A
				when x"B" => hex_string(2) := 'B'; -- B
				when x"C" => hex_string(2) := 'C'; -- C
				when x"D" => hex_string(2) := 'D'; -- D
				when x"E" => hex_string(2) := 'E'; -- E
				when x"F" => hex_string(2) := 'F'; -- F
			   when others => hex_string(2) := 'X'; -- X
			end case;
			
			-- Show at the hexadecimal base --
			hex_string(1) := 'H';
			
			return hex_string;
			
	end function stdLogicVectorToHexString;

	-- Constants --
	constant c_CLK_PERIOD : time := 20 ns; -- 50 MHz clock
	constant c_CLKS_PER_BIT : integer := 434; -- 50MHz/115,200 baud rate = 434 clks
	constant c_BIT_PERIOD : time := 8680 ns; -- 1/115,200 baud rate = 8680 ns
	
	-- Signals --
	
	-- Stimulus signals --
	signal i_clk       : std_logic;
	signal i_Rx_Serial : std_logic;
	
	-- Observed signal --
	signal r_PB_error   : std_logic; -- Parity Bit error
	signal r_Rx_DV   : std_logic; -- Data Valid
	signal r_Rx_Byte : std_logic_vector(7 downto 0);
	
	signal r_PB  : std_logic; -- Parity Bit
	
	-- Procedures -- NEED TO FIX THIS!!!!
	procedure UART_WRITE_BYTE (
		i_Data_in : in std_logic_vector(7 downto 0);
		variable Parity_Bit : inout std_logic;
		signal o_Serial_Data : out std_logic) is 
	begin
		-- Send Start Bit --
		o_Serial_Data <= '0';
		wait for c_BIT_PERIOD;

		
		-- Send Data Bits --
		for i in 0 to 7 loop
			Parity_Bit := Parity_Bit xor i_Data_in(i);
			o_Serial_Data <= i_Data_in(i);
			wait for c_BIT_PERIOD;
		end loop;
		
			-- Check if the massage arrived correctly --
		if (r_Rx_Byte = i_Data_in) then
			report stdLogicVectorToHexString(i_Data_in) & " Test Passed - Correct Byte Received" severity Note;
		else
			report stdLogicVectorToHexString(i_Data_in) & " Test Failed - Incorrect Byte Received" severity Note;
		end if;
		
		-- Send Parity bit -- NEED TO FIX THIS!!!!
			o_Serial_Data <= Parity_Bit;
			wait for c_BIT_PERIOD;
		
		-- Send Stop bit --
			Parity_Bit := '0';
			o_Serial_Data <= '1';
			wait for c_BIT_PERIOD;
			
	end procedure UART_WRITE_BYTE;

begin
	
	-- Unit Under Test port map --
	UUT : entity work.uartReceiver(rtl)
	generic map (g_CLKS_PER_BIT => c_CLKS_PER_BIT) -- 115,200 baud rate
	port map (
			i_clk  			 => i_clk ,
			UART_RXD  		 => i_Rx_Serial ,
			o_PB            => r_PB,
			LEDR(0)         => r_PB_error ,
			o_Rx_Data_Valid => r_Rx_DV ,
			o_Rx_Byte		 => r_Rx_Byte);
	
	
	-- Testbench process --
	p_TB : process
		variable Parity_Bit : std_logic := '0';
	begin
		-- Inital Setup --
		i_Rx_Serial <= '1'; -- IDLE

		
		-- Send 37H to the UART --
		wait until rising_edge(i_clk);
		UART_WRITE_BYTE (X"37" , Parity_Bit , i_Rx_Serial);

		-- Send 4DH to the UART --
		wait until rising_edge(i_clk);
		UART_WRITE_BYTE (X"4D" , Parity_Bit , i_Rx_Serial);
		
		assert false report "The tests are complete!" severity failure;

	wait;
	end process p_TB;
	
	
	-- 50 MHz clock in duty cycle of 50% - 20 ns -- 
	p_clock : process 
	begin 
		i_clk <= '0'; wait for c_CLK_PERIOD/2; -- 10 ns
		i_clk <= '1'; wait for c_CLK_PERIOD/2; -- 10 ns
	end process p_clock;

end architecture sim;