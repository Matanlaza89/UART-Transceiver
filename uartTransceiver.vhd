-----------------------------------------------------------------------------
----------------  This RTL Code written by Matan Leizerovich  ---------------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-------			          UART Transceiver Project            	       -------
-----------------------------------------------------------------------------
------ 	This project creates a  UART Transceiver that shares data
--       with the laptop and displays it on the 7 segment display
--           and the serial communication terminal on the laptop.      ------
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
------------------------------  PC Loopback Test  ---------------------------
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seven_segment_package.all; -- using binaryTo7Segment function


entity uartTransceiver is
	port (
		  -- Inputs --
		  CLOCK_50 : in std_logic;
		  --SW 	     : in std_logic_vector(9 downto 0);
		  UART_RXD : in std_logic;
		  
		  -- Outputs -- 
		  --LEDR : out std_logic_vector(0 downto 0);
		  UART_TXD    : out std_logic;
		  HEX0        : out std_logic_vector(6 downto 0);
		  HEX1   : out std_logic_vector(6 downto 0);
		  HEX2   : out std_logic_vector(6 downto 0);
		  HEX3   : out std_logic_vector(6 downto 0)
		  );
end entity uartTransceiver;

architecture rtl of uartTransceiver is
	
	-- Aliases -- 
	alias o_Tx_Serial  : std_logic is UART_TXD;
	alias i_Rx_Serial : std_logic is UART_RXD;
	--alias i_Data 	   : std_logic_vector is SW(7 downto 0);
	
	-- Signals --
	signal w_Tx_Serial : std_logic := '0';
	signal w_Tx_Active : std_logic := '0';
	signal w_Tx_Done   : std_logic := '0';
	
	signal w_PB : std_logic := '0';
	signal w_PB_error : std_logic := '0';
	signal w_Rx_Data_Valid : std_logic := '0';
	signal w_Rx_Byte : std_logic_vector(7 downto 0) := (others => '0');
	
	-- Constants -- 
	constant c_CLKS_PER_BIT : integer := 434; -- 50MHz/115,200 baud rate = 434
	
begin
	
	------- Instance of UART Receiver -------
	uart_rx : entity work.uartReceiver
	generic map(g_CLKS_PER_BIT => c_CLKS_PER_BIT) -- g_CLKS_PER_BIT for 115,200 baud rate
	port map (
			i_clk  			 => CLOCK_50 ,
			UART_RXD  		 => i_Rx_Serial ,
			o_PB            => w_PB ,
			LEDR(0)         => w_PB_error ,
			o_Rx_Data_Valid => w_Rx_Data_Valid,
			o_Rx_Byte		 => w_Rx_Byte);
	-------------------------------------------
	
	
	------- Instance of UART Transmitter -------
	uart_tx : entity work.uartTransmitter
	generic map(g_CLKS_PER_BIT => c_CLKS_PER_BIT) -- g_CLKS_PER_BIT for 115,200 baud rate
	port map (
			i_clk 		   => CLOCK_50 ,
			SW(7 downto 0) => w_Rx_Byte,
			SW(8) 		   => '0' ,
			SW(9) 		   => w_Rx_Data_Valid ,
			UART_TXD       => w_Tx_Serial,
			o_Tx_Active    => w_Tx_Active,
			o_Tx_Done	   => w_Tx_Done);
	-------------------------------------------
	
	
	-- Drive UART line high when transmitter is not active --
	o_Tx_Serial <= w_Tx_Serial when w_Tx_Active = '1' else '1';
	
	
	-- Display ASCII code in Hex base on 7 segments -- 
	HEX0 <= "0001001";
	HEX1 <= binaryTo7Segment(w_Rx_Byte(3 downto 0));
	HEX2 <= binaryTo7Segment(w_Rx_Byte(7 downto 4));
	HEX3 <= "1111111";
	
end architecture rtl;