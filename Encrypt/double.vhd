library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity double is
  port (
    clk     : in std_logic;  
    enable  : in std_logic;
    i_block : in std_logic_vector (63 downto 0);
    o_block : out std_logic_vector (63 downto 0)
  ) ;
end double ; 

architecture rtl of double is
    type block_arr is array (0 to 7) of std_logic_vector (7 downto 0);
    signal temp_block : block_arr;

    type state is (change1,change2);
    signal currstate : state := change1;
    -- := (X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00")
begin
    
    
    process(clk, enable, i_block)
    begin
      if enable = '1' then
        if rising_edge(clk) then
          temp_block(0) <= i_block (62 downto 56) & i_block (63);
          temp_block(1) <= i_block (54 downto 48) & i_block (55);
          temp_block(2) <= i_block (46 downto 40) & i_block (47);
          temp_block(3) <= i_block (38 downto 32) & i_block (39);
          temp_block(4) <= i_block (30 downto 24) & i_block (31);
          temp_block(5) <= i_block (22 downto 16) & i_block (23);
          temp_block(6) <= i_block (14 downto 8) & i_block (15);
          if i_block(63) = '0' then
              temp_block(7) <= i_block (6 downto 0) & i_block(7);
          else
              temp_block(7) <= (i_block (6 downto 0) & '0') XOR "00011011";
          end if;
        end if;
      else
        temp_block <= temp_block;
      end if;
    end process;
o_block <= temp_block(0) & temp_block(1) & temp_block(2) & temp_block(3) & temp_block(4) & temp_block(5) & temp_block(6) & temp_block(7);
end rtl ;