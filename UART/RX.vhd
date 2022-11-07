library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RX is
port(
	clk: in std_logic;
	rx_line: in std_logic;
	data: out std_logic_vector(7 downto 0);
	busy: out std_logic
);
end RX;

architecture rec of RX is
signal prscl: integer range 0 to 1250:=0; --12MHz/9600
signal index: integer range 0 to 9:=0;
signal datafll: std_logic_vector(9 downto 0);
signal rx_flg: std_logic:='0';--default 0

begin

	process(clk)
	begin
	if(rising_edge(clk)) then
	if(rx_flg='0' and rx_line='0') then
		index<=0;
		prscl<=0;
		busy<='1';--begining to Receive.
		rx_flg<='1';--RX_flag is set
	end if;
	
	if(rx_flg='1') then
			datafll(index)<=rx_line;--Register.
			if(prscl<1249) then
				prscl<=prscl+1;
			else
				prscl<=0;
			end if;
			
			if(prscl=600)then
				if(index<9) then
				index<=index+1;
				else
					if(datafll(0)='0' and datafll(9)='1') then--Control of start and stop bit.
						data<=datafll(8 downto 1);
					else
						data<=(others =>'0');
					end if;
					rx_flg<='0';--Reset rx flag
					busy<='0';--Ready for reading of coming data..
			end if;
		end if;
	end if;
end if;
end process;
end rec;