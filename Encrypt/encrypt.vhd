library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
    use ieee.std_logic_unsigned.all;

-- Assumming all input are 128 bit long

entity encrypt is
  port (
    flag	: out std_logic;
    clk     : in std_logic;
    enable  : in std_logic;
    N       : in std_logic_vector (127 downto 0);
    A       : in std_logic_vector (127 downto 0);
    M       : in std_logic_vector (127 downto 0);
    K       : in std_logic_vector (127 downto 0);
    C       : out std_logic_vector (127 downto 0);
    T       : out std_logic_vector (127 downto 0)
  ) ;
end encrypt ; 

architecture rtl of encrypt is
    signal y1                           : std_logic_vector (127 downto 0);
    signal y2,y3                        : std_logic_vector (127 downto 0);
    signal L,L2,L3,Ltrunc,Ltemp         : std_logic_vector (63 downto 0);

    signal selectorL                    : std_logic_vector (1 downto 0);
    signal enL, enG, engift,en2L,en3L	: std_logic := '0';

    signal gift_flag                    : std_logic :='0';
    signal reset_gift                   : std_logic := '0';

    --type step is (proses1, proses2, proses3, proses4, proses5, proses6, proses7, initial1, initial2);
    --signal currstep : step := initial1;
    type step is (S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15);
    signal currstep : step := S0;

component gift128 is
    port(
        reset   : in std_logic;
        clk     : in std_logic;
        enable  : in std_logic;
        P       : in std_logic_vector (127 downto 0);
        K       : in std_logic_vector (127 downto 0);
        C       : out std_logic_vector (127 downto 0);
        flag    : out std_logic
    );
end component;

component double is
    port(
        clk     : in std_logic;
        enable  : in std_logic;
        i_block : in std_logic_vector (63 downto 0);
        o_block : out std_logic_vector (63 downto 0)    
    );
end component;

component triple is
    port (
			clk     : in std_logic;
			enable  : in std_logic;
			i_block : in std_logic_vector (63 downto 0);
      o_block : out std_logic_vector (63 downto 0)
    );
end component;

component muxL is   -- choose between L or 2L or 3L
    port(
        identity    : in std_logic_vector (63 downto 0);
        double      : in std_logic_vector (63 downto 0);
        triple      : in std_logic_vector (63 downto 0);
        trunced     : in std_logic_vector (63 downto 0);
        result      : out std_logic_vector (63 downto 0);
        Lsel        : in std_logic_vector (1 downto 0)
    );
end component;

component regL is   -- control when output of L is being given
    port(
        clk		: in std_logic;
        enable  : in std_logic;
        i_data  : in std_logic_vector (63 downto 0);
        o_data  : out std_logic_vector (63 downto 0)
    );
end component;

component gfunction is -- g function of GIFT-COFB
    port(
        enable  : in std_logic;
        i_block : in std_logic_vector (127 downto 0);
        o_block : out std_logic_vector (127 downto 0) 
    );
end component;

begin
gift : gift128 port map (
    reset   => reset_gift,
    clk     => clk,
    enable  => engift,
    P       => y1,
    K       => K,
    C       => y2,
    flag    => gift_flag
);

Ldouble : double port map (
	enable		=> en2L,
    clk         => clk,
    i_block     => L,
    o_block     => L2
);

Ltriple : triple port map (
	enable		=> en3L,
    clk         => clk,
    i_block     => L,
    o_block     => L3
);

selectL : muxL port map (
    identity    => L,
    double      => L2,
    triple      => L3,
    trunced     => Ltrunc,
    result      => Ltemp,
    Lsel        => selectorL
);

registerL : regL port map (
	clk		=> clk,
    enable  => enL,
    i_data  => Ltemp,
    o_data  => L
);

gfunc : gfunction port map (
    enable      => enG,
    i_block     => y2,
    o_block     => y3
);



process (clk, enable)
    constant zero : std_logic_vector (63 downto 0) := (others => '0');
begin
    if enable = '1' then
        if rising_edge(clk) then
            case currstep is
                when S0 =>
										flag <= '0';
                    y1 <= N;
                    currstep <= S1;
                when S1 => -- y from nonce using round functiong (GIFT)
				    				engift <= '1';
                    
                    currstep <= S2;

                when S2 =>
                    if gift_flag = '1' then
                        -- Turn Off Gift
                        engift <= '0';
                        -- Trunc Y and save to L register
                        selectorL   <= "00";
                        Ltrunc      <= y2 (127 downto 64);
                        -- Calculate 3L
                        enL <= '1';
                        --en3L <= '1';
                        
                        currstep <= S3;
                    else
                        currstep <= S2;
                    end if;

                when S3 => 
                    reset_gift <= '1';
                    -- Insert 3L into register
                    en3L <= '1';
                    --enL <= '0';
                    selectorL <= "11";
                    
                    currstep <= S4;
                
                when S4 =>
                    -- Turn on G function (Updates y3 value)
                    enG <= '1';
                    -- Turn off reset gift
                    reset_gift <= '0';
                    -- Turn off L3 function
                    en3L <= '0';

                    currstep <= S5;

                when S5 =>
                    if y3 = y2 then
                        currstep <= S5;
                    else
                        -- turn off G function
                        enG <= '0';
                        -- Choose the updated L
                        selectorL <= "01";
                                                
                        currstep <= S6;
                    end if;

                when S6 =>
                    -- Update y1 value
                    y1 <= A XOR y3 XOR (Ltemp & zero);

                    currstep <= S7;

                when S7 =>
                    -- enable gift function
                    engift <= '1';
                    y1 <= y1;

                    currstep <= S8;
                
                when S8 =>
                    if gift_flag = '1' then
                        engift <= '0';
                        -- Calculate 3L
                        en3L <= '1';
                        
                        currstep <= S9;
                    else
                        currstep <= S8;
                    end if;

                when S9 =>
                    reset_gift <= '1';
                    -- Insert 3L into register
                    en3L <= '0';
                    --enL <= '0';
                    selectorL <= "11";
                    
                    -- Inserting Value into C
                    C <= M XOR y2;

                    currstep <= S10;

                when S10 =>
                    -- Turn on G Function
                    enG <= '1';
                    -- Turn off reset gift
                    reset_gift <= '0';
                    -- turn off L3 function
                    --en3L <= '0';

                    currstep <= S11;

                when S11 =>
                    if y3 = y2 then
                        currstep <= S11;
                    else
                        -- Turn off G Functin
                        enG <= '0';
                        -- Choose the updated L
                        selectorL <= "01";
                                               
                        currstep <= S12;
                    end if;

                when S12 =>
                    -- Update y1 value
                    y1 <= A XOR y3 XOR (Ltemp & zero);

                    currstep <= S13;

                when S13 =>
                    engift <= '1';

                    currstep <= S14;

                when S14 =>
                    if gift_flag = '1' then
                        engift <= '0';
                        -- Calculate 3L
                        T <= y2;
                        currstep <= S15;
                    else
                        currstep <= S14;
                    end if;

                when S15 =>
                    reset_gift <= '0';
                    flag <= '1';

                    currstep <= S15;
            end case;
        end if;
    end if;
end process;


end rtl ;