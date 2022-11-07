library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TX is

port(
	clk: in std_logic;
	start: in std_logic;
	busy: out std_logic;
	data: in std_logic_vector(7 downto 0);
	tx_line: out std_logic
);
end TX;

architecture xmit of TX is
signal prscl: integer range 0 to 1250:=0; --12MHz/9600
signal index: integer range 0 to 9:=0;
signal datafll: std_logic_vector(9 downto 0);
signal tx_flg: std_logic:='0';
begin

	process(clk)
	begin
	if(rising_edge(clk)) then
		if(tx_flg='0' and start='1') then
			tx_flg<='1';
			busy<='1';
			datafll(0)<='0';--Start Bit
			datafll(9)<='1';--Stop Bit
			datafll(8 downto 1) <= data;
		end if;
		
		if(tx_flg='1') then
			if(prscl<1249) then
				prscl<=prscl+1;
			else
				prscl<=0;
			end if;
			
			if(prscl=630)then
				tx_line<=datafll(index);
				if(index<9) then
					index<=index+1;
				else
					tx_flg<='0';--when communication is completed, go return.
					busy<='0';--Ready for start.
					index<=0;--Index is zero
				end if;
			end if;
		end if;
	end if;

	end process;
end xmit;