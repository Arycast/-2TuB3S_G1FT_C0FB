library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity gfunction is
  port (
    enable  : in std_logic;
    i_block : in std_logic_vector (127 downto 0);
    o_block : out std_logic_vector (127 downto 0)
  ) ;
end gfunction ; 

architecture rtl of gfunction is
  type block_arr is array (0 to 16) of std_logic_vector (7 downto 0);
  signal r_block  : block_arr;
begin
process (enable, i_block)
begin
  if enable = '1' then 
    r_block(0) <= i_block(63 downto 56);
    r_block(1) <= i_block(55 downto 48);
    r_block(2) <= i_block(47 downto 40);
    r_block(3) <= i_block(39 downto 32);
    r_block(4) <= i_block(31 downto 24);
    r_block(5) <= i_block(23 downto 16);
    r_block(6) <= i_block(15 downto 8);
    r_block(7) <= i_block(7 downto 0);

    r_block(8) <= i_block(126 downto 120) & i_block(119);
    r_block(9) <= i_block(118 downto 112) & i_block(111);
    r_block(10) <= i_block(110 downto 104) & i_block(103);
    r_block(11) <= i_block(102 downto 96) & i_block(95);
    r_block(12) <= i_block(94 downto 88) & i_block(87);
    r_block(13) <= i_block(86 downto 80) & i_block(79);
    r_block(14) <= i_block(78 downto 72) & i_block(71);
    r_block(15) <= i_block(70 downto 64) & i_block(127);
    
    o_block <= r_block(0) & r_block(1) & r_block(2) & r_block(3) & r_block(4) & r_block(5) & r_block(6) & r_block(7) & r_block(8) & r_block(9) & r_block(10) & r_block(11) & r_block(12) & r_block(13) & r_block(14) & r_block(15);
  else 
    o_block <= r_block(0) & r_block(1) & r_block(2) & r_block(3) & r_block(4) & r_block(5) & r_block(6) & r_block(7) & r_block(8) & r_block(9) & r_block(10) & r_block(11) & r_block(12) & r_block(13) & r_block(14) & r_block(15);
  end if;
end process;
end rtl ;