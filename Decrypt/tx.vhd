library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity tx is
    generic(
        clock_freq  : integer;
        baud_rate   : integer
);
    port (
    clk         : in std_logic;
    byte_tx     : in std_logic_vector (7 downto 0);
    tx_dv       : in std_logic;
    tx_serial   : out std_logic;
    tx_active   : out std_logic;
    tx_done     : out std_logic
);
end tx ; 

architecture transmitting of tx is
    constant baud_freq : integer := clock_freq/baud_rate-1;

    type state is (idle, start, dataIn, stop, clean);
    signal currState    : state                         := idle;
    signal baudCnt      : integer range 0 to baud_freq  := 0;
    signal index        : integer                       := 1;
    signal tx_data      : std_logic_vector (7 downto 0) := (others => '0');
    signal done         : std_logic                     := '0';

begin
process(clk)
begin
    if rising_edge(clk) then
        case currState is
            when idle =>
                tx_active   <= '0';
                tx_serial   <= '1';
                done        <= '0';
                baudCnt     <= 0;
                index       <= 0;

                if tx_dv = '1' then
                    tx_data     <= byte_tx;
                    currState   <= start;
                else
                    currState <= idle;
                end if;

            when start =>
                tx_active   <= '1';
                tx_serial   <= '0';
                
                if baudCnt < baud_freq - 1 then
                    baudCnt <= baudCnt + 1;
                    currState <= start;
                else
                    baudCnt <= 0;
                    currState <= dataIn;
                end if;

            when dataIn =>
                tx_serial <= tx_data(index);

                if baudCnt < baud_freq - 1 then
                    baudCnt <= baudCnt + 1;
                    currState <= dataIn;
                else
                    baudCnt <= 0;

                    if index < 7 then
                        index <= index + 1;
                        currState <= dataIn;
                    else
                        index <= 0;
                        currState <= stop;
                    end if;
                end if;
                
            when stop =>
                tx_serial <= '1';

                if baudCnt < baud_freq - 1 then
                    baudCnt     <= baudCnt + 1;
                    currState   <= stop;
                else
                    done        <= '1';
                    baudCnt     <= 0;
                    currState   <= clean;
                end if;
            
            when clean =>
                tx_active   <= '0';
                currState   <= idle;

        end case;
    end if;
end process;
tx_done <= done;
end transmitting ;