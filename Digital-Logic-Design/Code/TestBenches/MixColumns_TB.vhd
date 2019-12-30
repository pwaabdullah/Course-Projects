LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY MixColumns_TB IS
END MixColumns_TB;
 
ARCHITECTURE behavior OF MixColumns_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT MixColumns
    PORT(
         SYS_CLK : IN  std_logic;
         RST : IN  std_logic;
         DATA_IN : IN  std_logic_vector(127 downto 0);
         DATA_OUT : OUT  std_logic_vector(127 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal SYS_CLK : std_logic := '0';
   signal RST : std_logic := '0';
   signal DATA_IN : std_logic_vector(127 downto 0) := (others => '0');

 	--Outputs
   signal DATA_OUT : std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant SYS_CLK_period : time := 10 ns;
	
	SIGNAL CORRECT_OUTPUT : std_logic_vector(127 downto 0) := (others => '0');
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: MixColumns PORT MAP (
          SYS_CLK => SYS_CLK,
          RST => RST,
          DATA_IN => DATA_IN,
          DATA_OUT => DATA_OUT
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
      -- Stimulus process
      wait for 10 ns;
		DATA_IN 			<= X"db135345f20a225c01010101c6c6c6c6";
		CORRECT_OUTPUT <= X"8e4da1bc9fdc589d01010101c6c6c6c6";
		wait for 20 ns;
		DATA_IN 			<= X"d4bf5d30e0b452aeb84111f11e2798e5";
		CORRECT_OUTPUT <= X"046681e5e0cb199a48f8d37a2806264c";		
      wait;
   end process;

END;
