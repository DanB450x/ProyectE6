library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TransmisorE6 is
port(
clock: in std_logic;
txd: out std_logic);
end TransmisorE6;

architecture Behavioral of TransmisorE6 is
constant system_speed: natural := 50e6;

signal baudrate_clock, second_clock, old_second_clock: std_logic;
signal bit_counter: unsigned(3 downto 0) := x"9";
signal shift_register: unsigned(9 downto 0) := (others => '0');
signal char_index: natural range 0 to 18;
component clock_generator 
generic(clock_in_speed, clock_out_speed: integer);
port(
clock_in: in std_logic;
clock_out: out std_logic);
end component;

begin
baudrate_generator: clock_generator
generic map(clock_in_speed => system_speed, clock_out_speed => 9600)
port map(
clock_in => clock,
clock_out => baudrate_clock);

second_generator: clock_generator
generic map(clock_in_speed => system_speed, clock_out_speed => 1)
port map(
clock_in => clock,
clock_out => second_clock);

send: process(baudrate_clock)
begin
if baudrate_clock'event and baudrate_clock = '1' then
txd <= '1';
if bit_counter = 9 then
if second_clock /= old_second_clock then
old_second_clock <= second_clock;
if second_clock = '1' then
bit_counter <= x"0";
char_index <= char_index + 1;
case char_index is
when 0 =>
shift_register <= b"1" & x"50" & b"0";---P
when 1 =>
shift_register <= b"1" & x"41" & b"0";---A
when 2 =>
shift_register <= b"1" & x"4E" & b"0";---N
when 3 =>
shift_register <= b"1" & x"54" & b"0";---T
when 4 =>
shift_register <= b"1" & x"45" & b"0";---E
when 5 =>
shift_register <= b"1" & x"43" & b"0";---C
when 6 =>
shift_register <= b"1" & x"48" & b"0";---H
when 7 =>
shift_register <= b"1" & x"20" & b"0";
when 8 =>
shift_register <= b"1" & x"53" & b"0";---S
when 9 =>
shift_register <= b"1" & x"4F" & b"0";---O
when 10 =>
shift_register <= b"1" & x"4C" & b"0";---L
when 11 =>
shift_register <= b"1" & x"55" & b"0";---U
when 12 =>
shift_register <= b"1" & x"54" & b"0";---T
when 13 =>
shift_register <= b"1" & x"49" & b"0";---I
when 14 =>
shift_register <= b"1" & x"4F" & b"0";---O
when 15 =>
shift_register <= b"1" & x"4E" & b"0";---N
when 16 =>
shift_register <= b"1" & x"53" & b"0";---S
when 17 =>
shift_register <= b"1" & x"20" & b"0";---SPACE BAR
when 18 =>
shift_register <= b"1" & x"20" & b"0";--- SPACE BAR
char_index <= 0;
when others =>
char_index <= 0;
end case;
end if;
end if;
else
txd <= shift_register(0);
bit_counter <= bit_counter + 1;
shift_register <= shift_register ror 1;
end if;
end if;
end process;

end Behavioral;
