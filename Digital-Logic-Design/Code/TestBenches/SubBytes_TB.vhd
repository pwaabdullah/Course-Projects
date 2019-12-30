LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY SubBytes_TB IS
END SubBytes_TB;
 
ARCHITECTURE behavior OF SubBytes_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SubBytes
    PORT(
         SubBytes_IN : IN  std_logic_vector(127 downto 0);
         SubBytes_OUT : OUT  std_logic_vector(127 downto 0);
         SYS_CLK : IN  std_logic;
         RST : IN  std_logic
        );
    END COMPONENT;
	 
    

   --Inputs
   signal SubBytes_IN : std_logic_vector(127 downto 0) := (others => '0');
   signal SYS_CLK : std_logic := '0';
   signal RST : std_logic := '0';

 	--Outputs
   signal SubBytes_OUT : std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant SYS_CLK_period : time := 8 ns;
	
	SIGNAL CORRECT_OUTPUT : std_logic_vector(127 downto 0) := (others => '0');
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SubBytes PORT MAP (
          SubBytes_IN => SubBytes_IN,
          SubBytes_OUT => SubBytes_OUT,
          SYS_CLK => SYS_CLK,
          RST => RST
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
      -- hold reset state for 100 ms.
      wait for SYS_CLK_period*10;
		SubBytes_IN 	<= X"193de3bea0f4e22b9ac68d2ae9f84808";
		CORRECT_OUTPUT <= X"d42711aee0bf98f1b8b45de51e415230";
--		Wait for 16ns;
--		SubBytes_IN 	<= X"193de3bea0f4e22b9ac68d2ae9f84808";
--		CORRECT_OUTPUT <= X"d42711aee0bf98f1b8b45de51e415230";
      wait;
   end process;

END;
