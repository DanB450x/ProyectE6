LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY hex2led IS
	PORT (
		
		HEX : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		LED : OUT STD_LOGIC_VECTOR (0 TO 7)
	);
END hex2led;

ARCHITECTURE Behavioral OF hex2led IS

signal segment: std_logic_vector (0 to 6);
BEGIN

	WITH (HEX) SELECT	

	segment <= 		 "1000000" WHEN "0000", --0
						 "1111001" WHEN "0001", --1
						 "0100100" WHEN "0010", --2
						 "0110000" WHEN "0011", --3
						 "0011001" WHEN "0100", --4
						 "0010010" WHEN "0101", --5
						 "0000010" WHEN "0110", --6
						 "1111000" WHEN "0111", --7
						 "0000000" WHEN "1000", --8
						 "0010000" WHEN "1001", --9
						 "0001000" WHEN "1010", --A
						 "0000011" WHEN "1011", --b
						 "1000110" WHEN "1100", --C
						 "0100001" WHEN "1101", --d
						 "0000110" WHEN "1110", --E
						 "0001110" WHEN "1111", --F
						 "1011011" WHEN OTHERS; --x
	LED<='0'&segment;
END Behavioral;