library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity Mux2 is
   port
   (
      Mux2_In_1,Mux2_In_2		 : in std_logic_vector(3 downto 0);
		SEL			 : in std_logic;
      Mux2_Out 	 : out std_logic_vector(3 downto 0));
end entity Mux2; 
architecture Behavioral of Mux2 is
begin
		Mux2_Out <= Mux2_In_1 when (SEL = '0') else
						Mux2_In_2 when (SEL = '1') else
						"0000";
end architecture Behavioral;