LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY ShiftRows_TB IS
END ShiftRows_TB;
 
ARCHITECTURE behavior OF ShiftRows_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ShiftRows
    PORT(
         ShiftRows_In : IN  std_logic_vector(127 downto 0);
         ShiftRows_Out : OUT  std_logic_vector(127 downto 0);
         Sys_Clk : IN  std_logic;
         RST : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal ShiftRows_In : std_logic_vector(127 downto 0) := (others => '0');
   signal Sys_Clk : std_logic := '0';
   signal RST : std_logic := '0';

 	--Outputs
   signal ShiftRows_Out : std_logic_vector(127 downto 0);

   -- Clock period definitions
   constant Sys_Clk_period : time := 10 ns;
 
	SIGNAL CORRECT_OUTPUT : std_logic_vector(127 downto 0) := (others => '0');
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ShiftRows PORT MAP (
          ShiftRows_In => ShiftRows_In,
          ShiftRows_Out => ShiftRows_Out,
          Sys_Clk => Sys_Clk,
          RST => RST
        );

   -- Clock process definitions
   Sys_Clk_process :process
   begin
		Sys_Clk <= '0';
		wait for Sys_Clk_period/2;
		Sys_Clk <= '1';
		wait for Sys_Clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      wait for Sys_Clk_period*10;
		ShiftRows_In 	<= X"d42711aee0bf98f1b8b45de51e415230";
		CORRECT_OUTPUT <= X"d4bf5d30e0b452aeb84111f11e2798e5";
--		wait for 20ns;
--		ShiftRows_In 	<= X"49ded28945db96f17f39871a7702533b";
--		CORRECT_OUTPUT <= X"49db873b453953897f02d2f177de961a";		
      wait;
   end process;

END;
