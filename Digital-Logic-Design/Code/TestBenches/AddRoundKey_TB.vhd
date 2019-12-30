LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY AddRoundKey_TB IS
END AddRoundKey_TB;
 
ARCHITECTURE behavior OF AddRoundKey_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT AddRoundKey
    PORT(
         Data_IN : IN  std_logic_vector(127 downto 0);
         Key_IN : IN  std_logic_vector(127 downto 0);
         Data_OUT : OUT  std_logic_vector(127 downto 0);
         SYS_CLK : IN  std_logic;
         RST : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal Data_IN : std_logic_vector(127 downto 0) := (others => '0');
   signal Key_IN : std_logic_vector(127 downto 0) := (others => '0');
   signal SYS_CLK : std_logic := '0';
   signal RST : std_logic := '0';

 	--Outputs
   signal Data_OUT : std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant SYS_CLK_period : time := 10 ns;
 
	SIGNAL CORRECT_OUTPUT : std_logic_vector(127 downto 0) := (others => '0');
 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: AddRoundKey PORT MAP (
          Data_IN => Data_IN,
          Key_IN => Key_IN,
          Data_OUT => Data_OUT,
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
		wait for SYS_CLK_period*10;
		Data_IN 			<= X"3243f6a8885a308d313198a2e0370734";
		Key_IN			<= X"2b7e151628aed2a6abf7158809cf4f3c";
		CORRECT_OUTPUT <= X"193de3bea0f4e22b9ac68d2ae9f84808";
		wait for 20ns;
		Data_IN 			<= X"046681e5e0cb199a48f8d37a2806264c";
		Key_IN			<= X"aofafe1788542cb123a339392a6c7605";
		CORRECT_OUTPUT <= X"a49c7ff2689f352b6b5bea43026a5049";
      wait;
   end process;

END;
