-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			           UART Receiver Project            	          -------
-----------------------------------------------------------------------------
------- 	     This entity receives the UART data frame of 11 bits      ------  
-------      1 Start Bit , 8 Data bits , 1 Parity Bit , 1 Stop Bit     ------ 
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartReceiver is
generic (g_CLKS_PER_BIT : integer := 434); -- 50MHz / 115,200 Baud rate = 434
port (
		-- Inputs --
		i_Clk : in std_logic;
		UART_RXD : in std_logic;
		
		-- Outputs --
		o_PB : out std_logic; -- parity bit		
		LEDR : out std_logic_vector(0 downto 0);
		o_Rx_Data_Valid : out std_logic;
		o_Rx_Byte 		: out std_logic_vector(7 downto 0)
		);
end entity uartReceiver;

architecture rtl of uartReceiver is
	-- Aliases --
	alias i_Rx_Serial : std_logic is UART_RXD;
	alias o_parity_error : std_logic_vector(0 downto 0) is LEDR;
	
	-- Finitie State Machine - Enumeration -- 
	type t_state is (s_idle , s_Rx_Start_Bit , s_Rx_Data_Bits , s_Rx_Stop_Bit , s_Rx_Parity_Bit , s_Cleanup);
	
	-- Signals --
	signal r_state : t_state := s_idle;
	signal r_Clk_Counter : integer range 0 to g_CLKS_PER_BIT-1 := 0; -- Bit Width
	signal r_Bit_Index : integer range 0 to 7 := 0; -- 8 Data bit total
	signal r_Rx_Data_Valid : std_logic := '0';
	signal r_Rx_Byte : std_logic_vector(7 downto 0) := (others => '0');
	
	signal r_Parity_Bit : std_logic := '0'; -- Parity Bit
	signal r_PB_error: std_logic := '0';
	
begin
	-- This process receives the UART data frame --
	p_uart_receiver : process (i_Clk) is
		--variable r_Parity_Bit : std_logic := '0';
	begin
		if (rising_edge(i_Clk)) then
			
			case (r_state) is
				
				-- Receives low level in the serial input when IDLE --
				when s_idle => -- '1'
				
					-- initial values --
					r_Clk_Counter   <= 0;
					r_Bit_Index  	<= 0;
					r_Rx_Data_Valid <= '0';
					r_Parity_Bit <= '0';
					
					-- Look for start bit - falling_edge '1' to '0' transition --
					if (i_Rx_Serial = '0') then -- Start Bit detected
						r_state <= s_Rx_Start_Bit; 
						
					else
						r_state <= s_idle;
						
					end if; -- i_Rx_Serial
						
						
				-- Get a sample in the middle of the Start Bit --	
				when s_Rx_Start_Bit => 
					
					-- Wait for half of g_CLKS_PER_BIT clocks and then get a sample --
					if(r_Clk_Counter = (g_CLKS_PER_BIT-1)/2 ) then
						
						if (i_Rx_Serial = '0') then -- Avoid from a glitch , and verify this bit is the Start bit
							r_Clk_Counter <= 0;
							r_state <= s_Rx_Data_Bits;
							
						else -- found a glitch , go back to idle
							r_state <= s_idle;
							
						end if; -- i_Rx_Serial
						
					else
						r_Clk_Counter <= r_Clk_Counter + 1;
						r_state <= s_Rx_Start_Bit;
					
					end if; -- r_Clk_Counter for start bit
				
				-- Get a sample in the middle of the Data bits --
				when s_Rx_Data_Bits => 
				
					-- Wait for g_CLKS_PER_BIT clocks and then get a sample --
					if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
						r_Clk_Counter <= 0;
						r_Rx_Byte(r_Bit_Index) <= i_Rx_Serial;
						
						-- Calculation of Parity Bit --
						r_Parity_Bit <= r_Parity_Bit xor i_Rx_Serial;
							
						-- Check if we have sent out all the data bits --
						if (r_Bit_Index < 7) then
							r_Bit_Index <= r_Bit_Index + 1;
							r_state <= s_Rx_Data_Bits;
							
						else 
							r_Bit_Index <= 0;
							r_state <= s_Rx_Parity_Bit;
							
						end if; -- r_Bit_Index
						
					else
						r_Clk_Counter <= r_Clk_Counter + 1;
						r_state <= s_Rx_Data_Bits;
						
					end if; -- r_Clk_Counter for data bits
				
				-- Receive The parity bit to the serial output --
				when s_Rx_Parity_Bit =>

						o_PB <= r_Parity_Bit;
						
						-- Wait for g_CLKS_PER_BIT clocks and then get a sample --
						if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
							r_Clk_Counter <= 0;
							r_state <= s_Rx_Stop_Bit;
							
							if(r_Parity_Bit = i_Rx_Serial) then
								r_PB_error <= '0';
							else
								r_PB_error <= '1';
							end if; -- Check the integrity of the parity bit

						else
							r_Clk_Counter <= r_Clk_Counter + 1;
							r_state <= s_Rx_Parity_Bit;
							
						end if; -- r_Clk_Counter

						
				-- Receive the Stop bit which is high level --
				when s_Rx_Stop_Bit =>
				
						-- Wait for g_CLKS_PER_BIT clocks and then get a sample --
						if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
							r_Clk_Counter <= 0;
							r_Rx_Data_Valid <= '1';
							r_state <= s_Cleanup;

						else
							r_Clk_Counter <= r_Clk_Counter + 1;
							r_state <= s_Rx_Stop_Bit;
							
						end if; -- r_Clk_Counter
				
					
				 -- Stay here 1 clock --
				when s_Cleanup =>
					r_Rx_Data_Valid <= '0';
					r_state <= s_idle;

				when others => 
					r_state <= s_idle;
					
			end case; -- r_state of FSM
		
		end if; -- rising_edge(clk)
	
	end process p_uart_receiver;
	
	-- Update outputs --
	o_Rx_Data_Valid <= r_Rx_Data_Valid;
	o_Rx_Byte <= r_Rx_Byte;
	o_parity_error(0) <= r_PB_error;
	
	
	
end architecture rtl;