library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity muxL is
  port (
    identity    : in std_logic_vector (63 downto 0);
    double      : in std_logic_vector (63 downto 0);
    triple      : in std_logic_vector (63 downto 0);
    trunced     : in std_logic_vector (63 downto 0);
    result      : out std_logic_vector (63 downto 0);
    Lsel        : in std_logic_vector (1 downto 0)
  ) ;
end muxL ; 

architecture rtl of muxL is

begin
process(Lsel, identity, double, triple, trunced)
begin

    if Lsel = "01" then
        result <= identity;
    elsif Lsel = "10" then
        result <= double;
    elsif Lsel = "11" then
        result <= triple;
    else
        result <= trunced;
    end if;

end process;
end rtl ;