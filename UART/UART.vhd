library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
----UART CODE -----
--Tayfun Ozturk--
--This code was designed by Tayfun Ozturk--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART is
port(
	clock_12: in std_logic;--12 MHZ clock
	sw: in std_logic_vector(7 downto 0);--Switches
	key: in std_logic_vector(1 downto 0);--Keys or Buttons
	uart_txd: out std_logic;--? GPIO_P1
	uart_rxd: in std_logic;--? GPIO_P2
	SS_HEX1: out std_LOGIC_VECTOR(0 to 7);--Seven Segments...
	DataLed: out std_logic_vector (7 downto 0);
	SegmentEN : out std_logic
);
end UART;

architecture com of UART is
-----------------Signals--------------------------
signal tx_data: std_logic_vector(7 downto 0);
signal tx_start: std_logic:='0';
signal tx_busy: std_logic;
signal rx_data: std_logic_vector(7 downto 0);
signal rx_busy: std_logic;
signal RX_BIN: std_logic_vector(7 downto 0);

signal SS_in: STD_LOGIC_VECTOR (3 downto 0);
---------------Components-------------------------
component TX
port(
	clk: in std_logic;
	start: in std_logic;
	busy: out std_logic;
	data: in std_logic_vector(7 downto 0);
	tx_line: out std_logic
);
end component;
----------------------------------------------------
component RX
port(
	clk: in std_logic;
	rx_line: in std_logic;
	data: out std_logic_vector(7 downto 0);
	busy: out std_logic
);
end component;
----------------------------------------------------
component hex2led 
	PORT (
		HEX : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		LED : OUT STD_LOGIC_VECTOR (0 to 7)
	);
END component;
----------------------------------------------------
component Mux2 
   port
   (
      Mux2_In_1,Mux2_In_2		 : in std_logic_vector(3 downto 0);
		SEL			 : in std_logic;
      Mux2_Out 	 : out std_logic_vector(3 downto 0));
end component;
----------------------------------------------------
begin	
	SegmentEN<='0';
	c1: TX port map(	clk=>clock_12,
							start=>tx_start,
							busy=>tx_busy,
							data=>tx_data,
							tx_line=>uart_txd);
	c2: RX port map(	clk=>clock_12,
							rx_line=>uart_rxd,
							data=>rx_data,
							busy=>rx_busy);
		
	process(rx_busy)
	begin
		if(falling_edge(rx_busy)) then
			rx_BIN<=rx_data;
		end if;
	end process;
	DataLed<=rx_BIN;
	Multiplexer: Mux2 port map(Mux2_In_1=>rx_BIN(3 downto 0),
										Mux2_In_2=>rx_BIN(7 downto 4),
										SEL=>key(1),
										Mux2_Out=>SS_in);										
	SevenSegment1: hex2led port map(HEX=>SS_in,LED=>SS_HEX1);

	process(clock_12)
	begin
	if(rising_edge(clock_12)) then
		if(key(0)='0' and tx_busy='0') then
			tx_data<=sw;
			tx_start<='1';
		else
			tx_start<='0';
		end if;
	end if;
end process;
end com;
