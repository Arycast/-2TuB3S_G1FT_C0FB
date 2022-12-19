library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity toplevel_encrypt is
  generic (
    clock_freq  : integer   := 50_000_000;
    baud_rate   : integer   := 9600
  );
  port (
    clk   : in std_logic;
    -- UART
    UART_RXD  : in std_logic;
    UART_TXD  : out std_logic

  ) ;
end toplevel_encrypt ; 

architecture rtl of toplevel_encrypt is

-- SIGNALS USED
  -- For RX
  signal rx_flag        : std_logic;                        -- finish at a falling edge
  signal data_in        : std_logic_vector(7 downto 0);    -- Data received from UART on FPGA
	-- For TX
	signal en_tx          : std_logic;
	signal tx_out         : std_logic;                      -- Serial Data to be transferred from FPGA
	signal tx_flag        : std_logic;                      -- Finish transmitting at a falling edge
	signal data_out       : std_logic_vector (7 downto 0);  -- Data to transfer out

  -- Data Processing
	signal temp_data			: std_logic_vector (127 downto 0);
  signal en_encrypt     : std_logic;
  signal modify_flag    : std_logic;
  -- input for encryption
  signal nonce          : std_logic_vector (127 downto 0);
  signal ad             : std_logic_vector (127 downto 0);
  signal message        : std_logic_vector (127 downto 0);
  signal key            : std_logic_vector (127 downto 0);
  -- output from encryption
  signal cipher         : std_logic_vector (127 downto 0);
  signal tag            : std_logic_vector (127 downto 0);

	type state is (nonce0,nonce1,nonce2,nonce3,ad0,ad1,ad2,ad3,message0,message1,message2,message3,key0,key1,key2,key3,data0,data1,cipher0,cipher1,cipher2,cipher3,tag0,tag1,tag2,tag3,enter0,enter1,done);
	signal currstep 			: state := nonce0;

	component tx is
		generic(
			clock_freq  : integer := clock_freq;
			baud_rate   : integer := baud_rate
		);
		port (
			clk         : in std_logic;
			byte_tx     : in std_logic_vector (7 downto 0);
			tx_dv       : in std_logic;
			tx_serial   : out std_logic;
			tx_active   : out std_logic;
			tx_done     : out std_logic
		);
	end component;
	
	component rx
			generic(
			clock_freq  : integer := clock_freq;
			baud_rate   : integer := baud_rate
	);
			port (
			clk         : in std_logic;
			rx_serial   : in std_logic;
			rx_dv       : out std_logic;
			byte_rx     : out std_logic_vector (7 downto 0)
	);
	end component rx;
	
	component encrypt is
		port (
			clk     : in std_logic;
			enable  : in std_logic;
			N       : in std_logic_vector (127 downto 0);
			A       : in std_logic_vector (127 downto 0);
			M       : in std_logic_vector (127 downto 0);
			K       : in std_logic_vector (127 downto 0);
			C       : out std_logic_vector (127 downto 0);
			T       : out std_logic_vector (127 downto 0);
			flag	  : out std_logic
	) ;
	end component;

begin

transmitter : tx port map(
	clk         => clk,
	byte_tx     => data_out,
	tx_dv       => en_tx,
	tx_serial   => tx_out,
	tx_active   => tx_flag,
	tx_done     => open
);

receiver : rx port map(
	clk         => clk,
	rx_serial   => UART_RXD,
	rx_dv       => rx_flag,
	byte_rx     => data_in
);

encryption : encrypt port map(
	clk         => clk,
	enable      => en_encrypt,
	N           => nonce,
	A           => ad,
	M           => message,
	K           => key,
	C           => cipher,
	T           => tag,
	flag        => modify_flag
);
UART_TXD <= tx_out when tx_flag = '1' else '1';

process(clk,tx_flag,rx_flag)

constant nonce_msg		: std_logic_vector (63 downto 0) := X"4E6F6E6365203A20";
constant ad_msg				: std_logic_vector (47 downto 0) := X"0A4144203A20";
constant message_msg	: std_logic_vector (87 downto 0) := X"0A4D657373616765203A20";
constant key_msg			: std_logic_vector (55 downto 0) := X"0A4B6579203A20";
constant cipher_msg		: std_logic_vector (87 downto 0) := X"0A0A436970686572203A20";
constant tag_msg			: std_logic_vector (55 downto 0) := X"0A546167203A20";

variable count				: integer := 56;

begin
	if rising_edge(clk) then
		case currstep is
-- nonce input
			when nonce0 =>
				if tx_flag = '1' then
					currstep <= nonce0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= nonce_msg (count+7 downto count);
					currstep	<= nonce1;	-- continue to next state
				end if;

			when nonce1	=>
				en_tx				<= '1';
				if count >= 0 then
					count 		:= count - 8;
					currstep 	<= nonce0;	-- go to previous state
				else
					currstep 	<= nonce2;	-- continue to next state
					count			:= 120;
				end if;

			when nonce2 =>
				if rx_flag = '1' then
					currstep <= nonce3;		-- countinue to next state
				else
					currstep <= nonce2;		-- stay in same state
					en_tx		<= '0';
				end if;

			when nonce3 =>
				if rx_flag = '0' then
					nonce(count+7 downto count) <= data_in;	-- insert data
					if count > 0 then
						count := count - 8;
						currstep <= nonce2;	-- back to previous state
					else
						currstep <= ad0;		-- continue to next state
						count	:= 40;				-- change to next msb_index - 7
					end if ;
				else
					currstep <= nonce3;		-- stay in same state
				end if;
-- ad input
			when ad0 =>
				if tx_flag = '1' then
					currstep <= ad0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= ad_msg (count+7 downto count);
					currstep	<= ad1;	-- continue to next state
				end if;

			when ad1 =>
				en_tx				<= '1';
				if count >= 0 then
					count 		:= count - 8;
					currstep 	<= ad0;	-- go to previous state
				else
					currstep 	<= ad2;	-- continue to next state
					count			:= 120;
				end if;
				
			when ad2 =>
				en_tx		<= '0';
				if rx_flag = '1' then
					currstep <= ad3;		-- countinue to next state
				else
					currstep <= ad2;		-- stay in same state
				end if;

			when ad3 =>
				if rx_flag = '0' then
					ad(count+7 downto count) <= data_in;	-- insert data
					if count > 0 then
						count := count - 8;
						currstep <= ad2;	-- back to previous state
					else
						currstep <= message0;		-- continue to next state
						count	:= 80;				-- change to next msb_index - 7
					end if ;
				else
					currstep <= ad3;		-- stay in same state
				end if;
-- Message input
			when message0 =>
				if tx_flag = '1' then
					currstep <= message0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= message_msg (count+7 downto count);
					currstep	<= message1;	-- continue to next state
				end if;

			when message1 =>
				en_tx				<= '1';
				if count >= 0 then
					count 		:= count - 8;
					currstep 	<= message0;	-- go to previous state
				else
					currstep 	<= message2;	-- continue to next state
					count			:= 120;
				end if;

			when message2 =>
				en_tx		<= '0';
				if rx_flag = '1' then
					currstep <= message3;		-- countinue to next state
				else
					currstep <= message2;		-- stay in same state
				end if;

			when message3 =>
				if rx_flag = '0' then
					message(count+7 downto count) <= data_in;	-- insert data
					if count > 0 then
						count := count - 8;
						currstep <= message2;	-- back to previous state
					else
						currstep <= key0;		-- continue to next state
						count	:= 48;				-- change to next msb_index - 7
					end if ;
				else
					currstep <= message3;		-- stay in same state
				end if;
-- Key Input
			when key0 =>
				if tx_flag = '1' then
					currstep <= key0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= key_msg (count+7 downto count);
					currstep	<= key1;	-- continue to next state
				end if;

			when key1 =>
				en_tx				<= '1';
				if count >= 0 then
					count 		:= count - 8;
					currstep 	<= key0;	-- go to previous state
				else
					currstep 	<= key2;	-- continue to next state
					count			:= 120;
				end if;

			when key2 =>
			en_tx		<= '0';
				if rx_flag = '1' then
					currstep <= key3;		-- countinue to next state
				else
					currstep <= key2;		-- stay in same state
				end if;

			when key3 =>
				if rx_flag = '0' then
					key(count+7 downto count) <= data_in;	-- insert data
					if count > 0 then
						count := count - 8;
						currstep <= key2;	-- back to previous state
					else
						currstep <= data0;		-- continue to next state
						count	:= 80;				-- change to next msb_index - 7
					end if ;
				else
					currstep <= key3;		-- stay in same state
				end if;
-- Data Processing
			when data0 =>
				en_encrypt <= '1';
				currstep <= data1;

			when data1 =>
				if modify_flag = '1' then
					currstep <= cipher0;
					en_encrypt <= '0';
				else
					currstep <= data1;
				end if;
-- Cipher Output
			when cipher0 =>
				if tx_flag = '1' then
					currstep <= cipher0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= cipher_msg (count+7 downto count);
					currstep	<= cipher1;	-- continue to next state
				end if;

			when cipher1 =>
				en_tx				<= '1';
				if count > 0 then
					count 		:= count - 8;
					currstep 	<= cipher0;	-- go to previous state
				else
					currstep 	<= cipher2;	-- continue to next state
					count			:= 120;
				end if;

			when cipher2 =>
				if tx_flag = '1' then
					currstep <= cipher2;	-- stay in same state
				else
					en_tx			<= '0';
					data_out 	<= cipher (count+7 downto count);
					currstep	<= cipher3;	-- continue to next state
				end if ;

			when cipher3 =>
				en_tx				<= '1';
				if count > 0 then
					count 		:= count - 8;
					currstep 	<= cipher2;	-- go to previous state
				else
					currstep 	<= tag0;	-- continue to next state
					count			:= 48;
				end if;
-- Tag Output
			when tag0 =>
				if tx_flag = '1' then
					currstep <= tag0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= tag_msg (count+7 downto count);
					currstep	<= tag1;	-- continue to next state
				end if;

			when tag1 =>
				en_tx				<= '1';
				if count >= 0 then
					count 		:= count - 8;
					currstep 	<= tag0;	-- go to previous state
				else
					currstep 	<= tag2;	-- continue to next state
					count			:= 120;
				end if;

			when tag2 =>
				if tx_flag = '1' then
					currstep <= tag2;	-- stay in same state
				else
					en_tx			<= '0';
					data_out 	<= tag (count+7 downto count);
					currstep	<= tag3;	-- continue to next state
				end if ;

			when tag3 =>
				en_tx				<= '1';
				if count > 0 then
					count 		:= count - 8;
					currstep 	<= tag2;	-- go to previous state
				else
					currstep 	<= enter0;	-- continue to next state
				end if;
-- Enter Between Next Process
			when enter0 =>
				if tx_flag = '1' then
					currstep <= enter0;	-- stay in same state
				else
					en_tx 		<= '0';
					data_out 	<= X"0A";
					currstep	<= enter1;	-- continue to next state
				end if;

			when enter1 =>
				en_tx				<= '1';
					if count >= 0 then
						count 		:= count - 1;
						currstep 	<= enter0;	-- go to previous state
					else
						currstep 	<= done;	-- continue to next state
					end if;
-- Finishing
			when done =>
				if tx_flag = '0' then
					en_tx 		<= '0';
				end if;
				currstep		<= done;
				
		end case;		
	end if ;
end process;
end rtl ;