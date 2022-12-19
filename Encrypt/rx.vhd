library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity rx is
    generic(
        clock_freq  : integer;
        baud_rate   : integer
);
    port (
    clk         : in std_logic;
    rx_serial   : in std_logic;
    rx_dv        : out std_logic;
    byte_rx     : out std_logic_vector (7 downto 0)
);
end rx ; 

architecture receiving of rx is
    constant baud_freq : integer := clock_freq/baud_rate-1;

    type state is (idle, start, dataIn, stop, clean);
    signal currState    : state                         := idle;
    signal baudCnt      : integer range 0 to baud_freq  := 0;
    signal index        : integer                       := 0;
    signal rx_data      : std_logic_vector (7 downto 0) := (others => '0');
    signal receive      : std_logic                     := '0';

begin
process(clk)
begin
    if rising_edge(clk) then
        case currState is
            when idle =>
                baudCnt     <= 0;
                index       <= 0;
                receive   <= '0';

                if rx_serial =  '0' then
                    currState <= start;
                else
                    currState <= idle;
                end if;

            when start =>
                if baudCnt = baud_freq/2 then
                    if rx_serial = '0' then
                        baudCnt <= 0;
                        currState <= dataIn;
                    else
                        currState <= idle;
                    end if;
                else
                    baudCnt <= baudCnt + 1;
                    currState <= start;
                end if;

            when dataIn =>
            if baudCnt < baud_freq then
                baudCnt     <= baudCnt + 1;
                currState   <= dataIn;
            else
                baudCnt <= 0;
                rx_data(index) <= rx_serial;

                if index < 7 then
                    index       <= index + 1;
                    currState   <= dataIn;
                else
                    index <= 1;
                    currState <= stop;
                end if;
            end if;

            when stop =>
                if baudCnt < baud_freq then
                    baudCnt     <= baudCnt + 1;
                    currState   <= stop;
                else
                    receive     <= '1';
                    baudCnt     <= 0;
                    currState   <= clean; 
                end if;
            when clean =>
                receive     <= '0';
                currState   <= idle;
            

        end case;
    end if;
end process;
byte_rx <= rx_data;
rx_dv   <= receive;
end receiving ;