library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity regL is
  port (
    clk		: in std_logic;
    enable  : in std_logic;
    i_data  : in std_logic_vector (63 downto 0);
    o_data  : out std_logic_vector (63 downto 0)
  ) ;
end regL ; 

architecture rtl of regL is

begin
    process (clk, enable, i_data)
    begin
        if rising_edge(clk) then
			if enable = '1' then
				o_data <= i_data;
			end if;
        end if;
    end process;
end rtl ;