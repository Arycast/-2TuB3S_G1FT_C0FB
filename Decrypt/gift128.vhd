library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity gift128 is
  port (
    reset   : in std_logic;
    clk     : in std_logic;
    enable  : in std_logic;
    P       : in std_logic_vector (127 downto 0);
    K       : in std_logic_vector (127 downto 0);
    C       : out std_logic_vector (127 downto 0);
    flag	: out std_logic
  ) ;
end gift128 ; 

architecture rtl of gift128 is
    signal S0,S1,S2,S3,T                        : std_logic_vector (31 downto 0);
    signal W0,W1,W2,W3,W4,W5,W6,W7,T6,T7     : std_logic_vector (15 downto 0);
    signal C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,C10,C11,C12,C13,C14,C15 : std_logic_vector (7 downto 0);

    signal pos1, pos2, pos3, pos4               : integer;
    signal en_perm                              : std_logic := '0';
    signal round                                : integer := 0; --Value of 40 to 1
    
    type round_arr is array (0 to 39) of std_logic_vector (7 downto 0);
    constant gift_round                         : round_arr := (x"01", x"03", x"07", x"0F", x"1F", x"3E", x"3D", x"3B", x"37", x"2F", x"1E", x"3C", x"39", x"33", x"27", x"0E", x"1D", x"3A", x"35", x"2B", x"16", x"2C", x"18", x"30", x"21", x"02", x"05", x"0B", x"17", x"2E", x"1C", x"38", x"31", x"23", x"06", x"0D", x"1B", x"36", x"2D", x"1A");
    signal round_constant                       : std_logic_vector(7 downto 0);

    type step is (load, sub1, sub2, sub3, sub4, sub5, sub6, sub7, permBits, addRoundKey, keyUpdate1, keyUpdate2, final);
    signal currstep : step := load;


begin
process (clk,reset, enable,S0,S1,S2,S3,W0,W1,W2,W3,W4,W5,W6,W7,T6,T7,T)
begin
    if reset = '1' then
        currstep <= load;
        flag <= '0';
        round <= 0;
    else
        if enable = '1' then
            if rising_edge(clk) then
                case currstep is
                    when load =>
                        -- Loading PlainText
                        S0 <= P(127 downto 96);
                        S1 <= P(95 downto 64);
                        S2 <= P(63 downto 32);
                        S3 <= P(31 downto 0);

                        -- Loading Key
                        W0 <= K(127 downto 112);
                        W1 <= K(111 downto 96);
                        W2 <= K(95 downto 80);
                        W3 <= K(79 downto 64);
                        W4 <= K(63 downto 48);
                        W5 <= K(47 downto 32);
                        W6 <= K(31 downto 16);
                        W7 <= K(15 downto 0);

                        round <= 0;
                        flag <= '0';
                        currstep <= sub1;

                    when sub1 =>
                        S1 <= S1 XOR (S0 AND S2);
                        currstep <= sub2;

                    when sub2 =>
                        S0 <= S0 XOR (S1 AND S3);

                        currstep <= sub3;

                    when sub3 =>
                        S2 <= S2 XOR (S0 OR S1);
                        currstep <= sub4;

                    when sub4 =>
                        S3 <= S3 XOR S2;
                        currstep <= sub5;

                    when sub5 =>
                        S1 <= S1 XOR S3;
                        S3 <= NOT S3;
                        currstep <= sub6;

                    when sub6 =>
                        S2 <= S2 XOR (S0 AND S1);

                        T   <= S0;
                        S0  <= S3;
                        currstep <= sub7;

                    when sub7 =>
                        S3  <= T;
                        currstep <= permBits;

                    when permBits =>
                        -- PermBit for S0
                        S0(0) <= S0(0) OR S0(0); S0(1) <= S0(4) OR S0(4); S0(2) <= S0(8) OR S0(8); S0(3) <= S0(12) OR S0(12);
                        S0(4) <= S0(16) OR S0(16); S0(5) <= S0(20) OR S0(20); S0(6) <= S0(24) OR S0(24); S0(7) <= S0(28) OR S0(28);
                    
                        S0(8) <= S0(3) OR S0(3); S0(9) <= S0(7) OR S0(7); S0(10) <= S0(11) OR S0(11); S0(11) <= S0(15) OR S0(15);
                        S0(12) <= S0(19) OR S0(19); S0(13) <= S0(23) OR S0(23); S0(14) <= S0(27) OR S0(27); S0(15) <= S0(31) OR S0(31);
                    
                        S0(16) <= S0(2) OR S0(2); S0(17) <= S0(6) OR S0(6); S0(18) <= S0(10) OR S0(10); S0(19) <= S0(14) OR S0(14);
                        S0(20) <= S0(18) OR S0(18); S0(21) <= S0(22) OR S0(22); S0(22) <= S0(26) OR S0(26); S0 (23) <= S0(30) OR S0(30);
                    
                    
                        S0(24) <= S0(1) OR S0(1); S0(25) <= S0(5) OR S0(5); S0(26) <= S0(9) OR S0(9); S0(27) <= S0(13) OR S0(13);
                        S0(28) <= S0(17) OR S0(17); S0(29) <= S0(21) OR S0(21); S0(30) <= S0(25) OR S0(25); S0(31) <=  S0(29) OR S0(29);

                        -- PermBits for S1
                        S1(0) <= S1(1) OR S1(1); S1(1) <= S1(5) OR S1(5); S1(2) <= S1(9) OR S1(9); S1(3) <= S1(13) OR S1(13);
                        S1(4) <= S1(17) OR S1(17); S1(5) <= S1(21) OR S1(21); S1(6) <= S1(25) OR S1(25); S1(7) <= S1(29) OR S1(29);

                        S1(8) <= S1(0) OR S1(0); S1(9) <= S1(4) OR S1(4); S1(10) <= S1(8) OR S1(8); S1(11) <= S1(12) OR S1(12);
                        S1(12) <= S1(16) OR S1(16); S1(13) <= S1(20) OR S1(20); S1(14) <= S1(24) OR S1(24); S1(15) <= S1(28) OR S1(28);

                        S1(16) <= S1(3) OR S1(3); S1(17) <= S1(7) OR S1(7); S1(18) <= S1(11) OR S1(11); S1(19) <= S1(15) OR S1(15);
                        S1(20) <= S1(19) OR S1(19); S1(21) <= S1(23) OR S1(23); S1(22) <= S1(27) OR S1(27); S1(23) <= S1(31) OR S1(31);


                        S1(24) <= S1(2) OR S1(2); S1(25) <= S1(6) OR S1(6); S1(26) <= S1(10) OR S1(10); S1(27) <= S1(14) OR S1(14);
                        S1(28) <= S1(18) OR S1(18); S1(29) <= S1(22) OR S1(22); S1(30) <= S1(26) OR S1(26); S1(31) <=  S1(30) OR S1(30);

                        -- PermBits fOR ; S2
                        S2(0) <= S2(2) OR S2(2); S2(1) <= S2(6) OR S2(6); S2(2) <= S2(10) OR S2(10); S2(3) <= S2(14) OR S2(14);
                        S2(4) <= S2(18) OR S2(18); S2(5) <= S2(22) OR S2(22); S2(6) <= S2(26) OR S2(26); S2(7) <= S2(30) OR S2(30);
                    
                        S2(8) <= S2(1) OR S2(1); S2(9) <= S2(5) OR S2(5); S2(10) <= S2(9) OR S2(9); S2(11) <= S2(13) OR S2(13);
                        S2(12) <= S2(17) OR S2(17); S2(13) <= S2(21) OR S2(21); S2(14) <= S2(25) OR S2(25); S2(15) <= S2(29) OR S2(29);
                    
                        S2(16) <= S2(0) OR S2(0); S2(17) <= S2(4) OR S2(4); S2(18) <= S2(8) OR S2(8); S2(19) <= S2(12) OR S2(12);
                        S2(20) <= S2(16) OR S2(16); S2(21) <= S2(20) OR S2(20); S2(22) <= S2(24) OR S2(24); S2 (23) <= S2(28) OR S2(28);
                    
                    
                        S2(24) <= S2(3) OR S2(3); S2(25) <= S2(7) OR S2(7); S2(26) <= S2(11) OR S2(11); S2(27) <= S2(15) OR S2(15);
                        S2(28) <= S2(19) OR S2(19); S2(29) <= S2(23) OR S2(23); S2(30) <= S2(27) OR S2(27); S2(31) <=  S2(31) OR S2(31);

                        -- PermBits fOR ; S3
                        S3(0) <= S3(3) OR S3(3); S3(1) <= S3(7) OR S3(7); S3(2) <= S3(11) OR S3(11); S3(3) <= S3(15) OR S3(15);
                        S3(4) <= S3(19) OR S3(19); S3(5) <= S3(23) OR S3(23); S3(6) <= S3(27) OR S3(27); S3(7) <= S3(31) OR S3(31);
                    
                        S3(8) <= S3(2) OR S3(2); S3(9) <= S3(6) OR S3(6); S3(10) <= S3(10) OR S3(10); S3(11) <= S3(14) OR S3(14);
                        S3(12) <= S3(18) OR S3(18); S3(13) <= S3(22) OR S3(22); S3(14) <= S3(26) OR S3(26); S3(15) <= S3(30) OR S3(30);
                    
                        S3(16) <= S3(1) OR S3(1); S3(17) <= S3(5) OR S3(5); S3(18) <= S3(9) OR S3(9); S3(19) <= S3(13) OR S3(13);
                        S3(20) <= S3(17) OR S3(17); S3(21) <= S3(21) OR S3(21); S3(22) <= S3(25) OR S3(25); S3 (23) <= S3(29) OR S3(29);
                    
                    
                        S3(24) <= S3(0) OR S3(0); S3(25) <= S3(4) OR S3(4); S3(26) <= S3(8) OR S3(8); S3(27) <= S3(12) OR S3(12);
                        S3(28) <= S3(16) OR S3(16); S3(29) <= S3(20) OR S3(20); S3(30) <= S3(24) OR S3(24); S3(31) <=  S3(28) OR S3(28);

                        currstep <= addRoundKey;

                    when addRoundKey =>
                        S2 <= S2 XOR (W2 & W3);
                        S1 <= S1 XOR (W6 & W7);
                        S3 <= S3 XOR (X"800000" & gift_round(round));
                        round_constant <= gift_round(round);
                        --S3 <= S3 XOR (X"800000" & gift_round(round));
                        --gift_round(upper downto lower);

                        currstep <= keyUpdate1;

                    when keyUpdate1 =>
                        --if round < 39 then
                            T6 <= W6(1 downto 0) & W6(15 downto 2);    -- temporary rotation of W6 (W6 >>> 2)
                            T7 <= W7(11 downto 0) & W7(15 downto 12);   -- temporary rotation of W7 (W7 >>> 12)
                            

                            currstep <= keyUpdate2;
                        --end if;

                    when keyUpdate2 =>
                        W0 <= T6;
                        W1 <= T7;
                        W2 <= W0;
                        W3 <= W1;
                        W4 <= W2;
                        W5 <= W3;
                        W6 <= W4;
                        W7 <= W5;
                        if round < 39 then
                            round <= round + 1;
                            currstep <= sub1;
                        else
                            currstep <= final;
                        end if;

                    when final =>
                        C0 <= S0 (31 downto 24);
                        C1 <= S0 (23 downto 16);
                        C2 <= S0 (15 downto 8);
                        C3 <= S0 (7 downto 0);
                        C4 <= S1 (31 downto 24);
                        C5 <= S1 (23 downto 16);
                        C6 <= S1 (15 downto 8);
                        C7 <= S1 (7 downto 0);
                        C8 <= S2 (31 downto 24);
                        C9 <= S2 (23 downto 16);
                        C10 <= S2 (15 downto 8);
                        C11 <= S2 (7 downto 0);
                        C12 <= S3 (31 downto 24);
                        C13 <= S3 (23 downto 16);
                        C14 <= S3 (15 downto 8);
                        C15 <= S3 (7 downto 0);
                        flag <= '1';
                end case;
            end if;
        end if;
    end if;
end process;
C <= C0 & C1 & C2 & C3 & C4 & C5 & C6 & C7 & C8 & C9 & C10 & C11 & C12 & C13 & C14 & C15;
end rtl ;