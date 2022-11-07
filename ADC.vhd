----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:46:55 05/13/2014 
-- Design Name: 
-- Module Name:    Main - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- I have uncommented this one
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity adcdac is
port( enable      :in std_logic; --switch to start preamp and adc. (L13)
		LED         :out std_logic_vector(7 downto 0);
		clk_50      :in std_logic;
		SPI_MISO    :in std_logic; --from adc to FPGA. Master Input, Slave Output. This is the serial data output of the adc to the FPGA. (N10)
		AD_CONV     :out std_logic; --from FPGA to adc. It is the triggering the analog-to-digital conversion. (P11, internal)
		AMP_CS      :out std_logic; --from FPGA to amp. It is an active low chip select signal. The gain is set when it goes high. (N7)
		SPI_MOSI    :out std_logic; --from FPGA to amp. Master Output, Slave Input. It presents the 8bit programmable gain settings. (T4)
		SPI_SCK     :inout std_logic; --from FPGA to amp/from FPGA to adc. SPI_MOSI and SPI_MISO send one bit at every rising edge of this clock. (U16)
		AMP_SHDN    :out std_logic; --from FPGA to amp. It is an active high reset signal. (P7)
		SPI_SS_B    :out std_logic; --DEACTIVATION
		SF_CE0      :out std_logic; --DEACTIVATION
		FPGA_INIT_B :out std_logic; --DEACTIVATION
		DAC_CS      :out std_logic := '1'); --DEACTIVATION
end adcdac;

architecture Behavioral of adcdac is

	type state_type is (IDLE, SETAMP, START_AD, ADC, FUNC, SET, SENDBIT, THEEND);
	
	signal state: state_type := IDLE;
	signal risingedge :std_logic := '1';
	signal clk_counter :integer range 0 to 25 := 0;
	signal ADC1 : signed (13 downto 0):= (others => '0');  -- Data from ADC1 (VIN A)
   signal ADC2 : signed (13 downto 0):= (others => '0');  -- Data from ADC2 (VIN B)
	signal dacdata: signed(32 downto 0) := (others => '0');
	signal dacsend : signed(11 downto 0) := (others => '0');
 
	signal count1 : integer range 0 to 13; --14bits fot 1 ADC channel and + 2 zeros
	signal count2 : integer range 0 to 13; --14bits fot 2 ADC channel and + 2 zeros
	signal gaincount : integer range 0 to 7; --8bits for preamplifier signal.
	signal daccounter: integer range 0 to 32; --DAC counter for loop
	signal adccounter: integer range 0 to 34; --34 spi_sck cycles for an entire ADC-loop.
	
	constant number_int: integer := 2;
	signal number_sig: signed (11 downto 0) := ( others=> '0');
	
	constant MAXDIG  : real := real(2 ** 14);
	constant VREF    : real := 1.65;--2.43;  -- or whatever you have as a reference
	constant analog    : real := 0.5;   -- analog voltage into converter
	signal adcval    : signed(13 downto 0);

begin

adcval <= to_signed(integer(MAXDIG * analog / VREF), 14); 

--This is a clock devider in order to get a 2MHz clock.
process(clk_50)
begin
	if rising_edge(clk_50) then
		if (clk_counter = 25) then
			risingedge <= risingedge xor '1';
			clk_counter <= 0;
		else
			clk_counter <= clk_counter + 1;
		end if;
	end if;
end process;

SPI_SCK <= risingedge;

--This is in order to deactivate other functions that the SPI has.
SPI_SS_B <= '0';
SF_CE0 <= '1';
FPGA_INIT_B <= '1';

process(SPI_SCK)

	constant gain : std_logic_vector(7 downto 0) := "00010001"; --This is the gain of the A and B preamplifiers corresponding to A and B ADCs. (0, 0)
	
begin
		if rising_edge(SPI_SCK) then
			case state is 
						
						when IDLE => 
							if (enable = '1') then 
								gaincount <= 7;
								state <= SETAMP; 
							else
								AMP_SHDN <= '1'; 
								AMP_CS <= '1'; 
								AD_CONV <= '1';
								DAC_CS <= '1';
								state <= IDLE; 
							end if;
									
						when SETAMP => --amplifier gain is set.
								AMP_SHDN <= '0'; 
								AMP_CS <= '0'; 
							if gaincount = 0 then
								SPI_MOSI <= gain(gaincount);
								state <= START_AD;
							else
								SPI_MOSI <= gain(gaincount);
								gaincount <= gaincount - 1;
								state <= SETAMP;
							end if;
							
						when START_AD => --analog-to-digital conversion starts.
								SPI_MOSI <= '0';
								AMP_SHDN <= '1';
								AMP_CS <= '1';
								AD_CONV <= '0'; 
								adccounter <= 0; 
								count1 <= 13; 
								count2 <= 13;	
								state <= ADC; 
												
						when ADC =>
							if adccounter <= 2 then --(0,1,2)
								adccounter <= adccounter + 1;
								state <= ADC;
							elsif adccounter > 2 and adccounter <= 16 then
								adccounter <= adccounter + 1;--(3,4,5,6,7,8,9,10,11,12,13,14,15,16)
								ADC1(count1) <= SPI_MISO;
								count1 <= count1 - 1;
								state <= ADC;
							elsif adccounter > 16 and adccounter <= 18 then --(17,18)
								adccounter <= adccounter + 1;
								state <= ADC;
							elsif adccounter > 18 and adccounter <= 32 then
								adccounter <= adccounter + 1;--(19,20,21,22,23,24,25,26,27,28,29,30,31,32)
								ADC2(count2) <= SPI_MISO;
								count2 <= count2 - 1;
								state <= ADC;
							elsif adccounter = 33 then
								adccounter <= adccounter + 1;
								state <= FUNC;								
							end if;
							
--						when ADC =>
--							if adccounter <= 2 then --(0,1,2)
--								adccounter <= adccounter + 1;
--								state <= ADC;
--							elsif adccounter = 3 then
--								adccounter <= adccounter + 1;
--								ADC1(13) <= adcval(13);
--								state <= ADC;
--							elsif adccounter = 4 then
--								adccounter <= adccounter + 1;
--								ADC1(12) <= adcval(12);
--								state <= ADC;
--							elsif adccounter = 5 then
--								adccounter <= adccounter + 1;
--								ADC1(11) <= adcval(11);
--								state <= ADC;
--							elsif adccounter = 6 then
--								adccounter <= adccounter + 1;
--								ADC1(10) <= adcval(10);
--								state <= ADC;
--							elsif adccounter = 7 then
--								adccounter <= adccounter + 1;
--								ADC1(9) <= adcval(9);
--								state <= ADC;
--							elsif adccounter = 8 then
--								adccounter <= adccounter + 1;
--								ADC1(8) <= adcval(8);
--								state <= ADC;
--							elsif adccounter = 9 then
--								adccounter <= adccounter + 1;
--								ADC1(7) <= adcval(7);
--								state <= ADC;
--							elsif adccounter = 10 then
--								adccounter <= adccounter + 1;
--								ADC1(6) <= adcval(6);
--								state <= ADC;
--							elsif adccounter = 11 then
--								adccounter <= adccounter + 1;
--								ADC1(5) <= adcval(5);
--								state <= ADC;
--							elsif adccounter = 12 then
--								adccounter <= adccounter + 1;
--								ADC1(4) <= adcval(4);
--								state <= ADC;
--							elsif adccounter = 13 then
--								adccounter <= adccounter + 1;
--								ADC1(3) <= adcval(3);
--								state <= ADC;
--							elsif adccounter = 14 then
--								adccounter <= adccounter + 1;
--								ADC1(2) <= adcval(2);
--								state <= ADC;
--							elsif adccounter = 15 then
--								adccounter <= adccounter + 1;
--								ADC1(1) <= adcval(1);
--								state <= ADC;
--							elsif adccounter = 16 then
--								adccounter <= adccounter + 1;
--								ADC1(0) <= adcval(0);
--								state <= ADC;
--								
--							elsif adccounter = 17 then
--								adccounter <= adccounter + 1;
--								state <= ADC;
--							elsif adccounter = 18 then
--								adccounter <= adccounter + 1;
--								state <= ADC;
--								
--							elsif adccounter = 19 then
--								adccounter <= adccounter + 1;
--								ADC2(13) <= adcval(13);
--								state <= ADC;
--							elsif adccounter = 20 then
--								adccounter <= adccounter + 1;
--								ADC2(12) <= adcval(12);
--								state <= ADC;
--							elsif adccounter = 21 then
--								adccounter <= adccounter + 1;
--								ADC2(11) <= adcval(11);
--								state <= ADC;
--							elsif adccounter = 22 then
--								adccounter <= adccounter + 1;
--								ADC2(10) <= adcval(10);
--								state <= ADC;
--							elsif adccounter = 23 then
--								adccounter <= adccounter + 1;
--								ADC2(9) <= adcval(9);
--								state <= ADC;
--							elsif adccounter = 24 then
--								adccounter <= adccounter + 1;
--								ADC2(8) <= adcval(8);
--								state <= ADC;
--							elsif adccounter = 25 then
--								adccounter <= adccounter + 1;
--								ADC2(7) <= adcval(7);
--								state <= ADC;
--							elsif adccounter = 26 then
--								adccounter <= adccounter + 1;
--								ADC2(6) <= adcval(6);
--								state <= ADC;
--							elsif adccounter = 27 then
--								adccounter <= adccounter + 1;
--								ADC2(5) <= adcval(5);
--								state <= ADC;
--							elsif adccounter = 28 then
--								adccounter <= adccounter + 1;
--								ADC2(4) <= adcval(4);
--								state <= ADC;
--							elsif adccounter = 29 then
--								adccounter <= adccounter + 1;
--								ADC2(3) <= adcval(3);
--								state <= ADC;
--							elsif adccounter = 30 then
--								adccounter <= adccounter + 1;
--								ADC2(2) <= adcval(2);
--								state <= ADC;
--							elsif adccounter = 31 then
--								adccounter <= adccounter + 1;
--								ADC2(1) <= adcval(1);
--								state <= ADC;
--							elsif adccounter = 32 then
--								adccounter <= adccounter + 1;
--								ADC2(0) <= adcval(0);
--								state <= ADC;
--								
--							elsif adccounter = 33 then
--								adccounter <= adccounter + 1;
--								state <= FUNC;
--							end if;
								
						when FUNC =>
								number_sig <= to_signed(number_int,12);
								dacsend <= resize(ADC1 * number_sig, 12);
								state <= SET;
								
						when SET =>
								dacdata <= "00000000" & "0011" & "1111" & dacsend & "00000"; -- (x8)zeros + (x4)command + (x4)adress + (x12)data + (x5)zeros
								daccounter <= 32;
								DAC_CS <= '0';
								state <= SENDBIT;
								
						when SENDBIT =>
							if daccounter = 0 then
								state <= THEEND;
							elsif daccounter > 0 then
								SPI_MOSI <= dacdata(daccounter);
								daccounter <= daccounter - 1;
								state <= SENDBIT;
							end if;
							
						when THEEND =>
								LED(0) <= gain(7);
								LED(1) <= gain(6);
								LED(2) <= gain(5);
								LED(3) <= gain(4);
								LED(4) <= gain(3);
								LED(5) <= gain(2);
								LED(6) <= gain(1);
								LED(7) <= gain(0);
								DAC_CS <= '1';
								ADC1 <= (others => '0');
								ADC2 <= (others => '0');
								dacsend <= (others => '0');
								dacdata <= (others => '0');
								state <= IDLE ;
	
			end case;
		end if;

end process;

end Behavioral;

