-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			           UART Transmitter Project            	      -------
-----------------------------------------------------------------------------
---------- 	  This entity sends the UART data frame of 11 bits     ----------
---------- 	1 Start Bit , 8 Data bits , 1 Parity Bit , 1 Stop Bit  ----------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartTransmitter is
	generic (g_CLKS_PER_BIT : integer := 434); -- 50MHz / 115,200 Baud rate = 434
	port (
		  -- Inputs --
		  i_clk 	 : in std_logic;
		  SW 			 : in std_logic_vector(9 downto 0);
		  
		  -- Outputs --
		  UART_TXD    : out std_logic;
		  o_Tx_Active : out std_logic;
		  o_Tx_Done   : out std_logic
		  );
end entity uartTransmitter;

architecture rtl of uartTransmitter is	
	-- Aliases -- 
	alias o_Tx_Serial  : std_logic is UART_TXD;
	alias i_Data 	   : std_logic_vector is SW(7 downto 0);
	alias i_Data_Valid : std_logic is SW(9);
	
	-- Finitie State Machine - Enumeration -- 
	type t_state is (s_idle , s_Tx_Start_Bit , s_Tx_Data_Bits , s_Tx_Parity_Bit , s_Tx_Stop_Bit ,s_Cleanup);
	
	-- Signals --
	signal r_state : t_state := s_idle;
	signal r_Clk_Counter : integer range 0 to g_CLKS_PER_BIT-1 := 0; -- Bit Width
	signal r_Bit_Index : integer range 0 to 7 := 0; -- 8 bits Data total
	signal r_Parity_Bit : std_logic := '0'; -- Even Parity bit
	signal r_Tx_Byte : std_logic_vector(7 downto 0);
	signal r_Tx_Done : std_logic := '0';
	
begin
	-- This process sends the UART data frame --
	p_uart_transmitter : process (i_clk) is
	begin	
		if (rising_edge(i_clk)) then
			
			case (r_state) is
				
				-- Send high level to the serial output when IDLE --
				when s_idle => 
					o_Tx_Serial <= '1';
					
					if (i_Data_Valid = '1') then
						r_Tx_Byte <= i_Data; -- Parallel Load
						r_state   <= s_Tx_Start_Bit; 
						
					else
						r_state <= s_idle;
						
					end if; -- i_Data_Valid
						
				-- Send low level to the serial output for Start Bit of the UART's frame --
				when s_Tx_Start_Bit =>
					o_Tx_Active <= '1';
					o_Tx_Serial <= '0';
					
					-- Send this bit for g_CLKS_PER_BIT clocks --
					if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
						r_Clk_Counter <= 0;
						r_state <= s_Tx_Data_Bits;
						
					else
						r_Clk_Counter <= r_Clk_Counter + 1;
						r_state <= s_Tx_Start_Bit;
					
					end if; -- r_Clk_Counter
				
				-- Send the Data bits to the serial output , LSB TO MSB --
				when s_Tx_Data_Bits => 
					o_Tx_Serial <= r_Tx_Byte(r_Bit_Index);
					
					-- Send this bit for g_CLKS_PER_BIT clocks --
					if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
						r_Clk_Counter <= 0;
						
						-- Check if we have sent out all the data bits --
						if (r_Bit_Index < 7) then
							-- Update Parity Bit Calculation --
							r_Parity_Bit <= r_Parity_Bit xor r_Tx_Byte(r_Bit_Index);
							
							r_Bit_Index <= r_Bit_Index + 1;
							r_state <= s_Tx_Data_Bits;
							
						else 
							r_Bit_Index <= 0;
							r_state <= s_Tx_Parity_Bit;
							
						end if; -- r_Bit_Index
						
					else
						r_Clk_Counter <= r_Clk_Counter + 1;
						r_state <= s_Tx_Data_Bits;
						
					end if; -- r_Clk_Counter
				
				-- Send EVEN parity bit to the serial output --
				when s_Tx_Parity_Bit =>
						o_Tx_Serial <= r_Parity_Bit;
						
						-- Send Pairity Bit for g_CLKS_PER_BIT clocks --
						if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
							r_Clk_Counter <= 0;
							r_state <= s_Tx_Stop_Bit;

						else
							r_Clk_Counter <= r_Clk_Counter + 1;
							r_state <= s_Tx_Parity_Bit;
							
						end if; -- r_Clk_Counter
				
				-- Send high level to the serial output for Stop Bit of the UART's frame --
				when s_Tx_Stop_Bit =>
						o_Tx_Serial <= '1';
						
						-- Send this bit for g_CLKS_PER_BIT clocks --
						if(r_Clk_Counter = (g_CLKS_PER_BIT-1) ) then
							r_Clk_Counter <= 0;
							r_Tx_Done <= '1';
							r_state <= s_Cleanup;

						else
							r_Clk_Counter <= r_Clk_Counter + 1;
							r_state <= s_Tx_Stop_Bit;
							
						end if; -- r_Clk_Counter
				
					
				 -- Stay here 1 clock --
				when s_Cleanup =>
					o_Tx_Active <= '0';
					r_Tx_Done <= '1';
					r_state <= s_idle;

				when others => 
					r_state <= s_idle;
					
			end case; -- r_state of FSM
		
		end if; --rising_edge(clk)
	
	end process p_uart_transmitter;
	
	-- Update when the transmission is over --
	o_Tx_Done <= r_Tx_Done;
	
end architecture rtl;