LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY Key_Schedule_128_TB IS
END Key_Schedule_128_TB;
 
ARCHITECTURE behavior OF Key_Schedule_128_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Key_Schedule_128
    PORT(
         SYS_CLK : IN  std_logic;
         RST : IN  std_logic;
         KEY_128 : IN  std_logic_vector(127 downto 0);
         PAR_KEY : OUT  std_logic_vector(127 downto 0);
         LOAD_KEY : IN  std_logic;
         EXP_KEY : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal SYS_CLK : std_logic := '0';
   signal RST : std_logic := '0';
   signal KEY_128 : std_logic_vector(127 downto 0) := (others => '0');
   signal LOAD_KEY : std_logic := '0';
   signal EXP_KEY : std_logic := '0';

 	--Outputs
   signal PAR_KEY : std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant SYS_CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Key_Schedule_128 PORT MAP (
          SYS_CLK => SYS_CLK,
          RST => RST,
          KEY_128 => KEY_128,
          PAR_KEY => PAR_KEY,
          LOAD_KEY => LOAD_KEY,
          EXP_KEY => EXP_KEY
        );

   -- Clock process definitions
   SYS_CLK_process :process
   begin
		SYS_CLK <= '0';
		wait for SYS_CLK_period/2;
		SYS_CLK <= '1';
		wait for SYS_CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      wait for SYS_CLK_period*10;
		KEY_128 <= X"2b7e151628aed2a6abf7158809cf4f3c";   ----Example Key from Rjindael flash Animation: http://www.formaestudio.com/rijndaelinspector/archivos/rijndaelanimation.html
		LOAD_KEY <= '1';  --Load the key
		wait for 10 ns;
		wait for 10 ns;
		EXP_KEY <= '1';  --Enable Key Expansion
		wait for 400ns;  ---Standard time frame for generating all 10 keys
		EXP_KEY <= '0';
--		wait for 10 ns;
--		KEY_128 <= X"000102030405060708090A0B0C0D0E0F";
--		LOAD_KEY <= '1';
--		wait for 10 ns;
--		EXP_KEY <= '1';
--		wait for 400ns;
--		EXP_KEY <= '0';
--		wait for 10 ns;
--		EXP_KEY <= '1';		
		WAIT;
   end process;

END;
