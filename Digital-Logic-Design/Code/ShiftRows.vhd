----------------------------------------------------------------------------------
-- Company: KFUPM
-- Student Name: Abdullah Al Mamun
-- Student Id: 201403680
-- Create Date:    17:44:53 02/11/2015 
-- Design Name: 
-- Module Name:    ShiftRows - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ShiftRows is
    Port ( ShiftRows_In : in  STD_LOGIC_VECTOR (127 downto 0);
           ShiftRows_Out : out  STD_LOGIC_VECTOR (127 downto 0);
           Sys_Clk,RST : in  STD_LOGIC);
end ShiftRows;

architecture Behavioral of ShiftRows is

begin
SHIFT_ROWS_MIXING : PROCESS(SYS_CLK)
begin
	IF (SYS_CLK'event AND SYS_CLK ='1') then
		IF RST = '1' then
			ShiftRows_Out <= (OTHERS => '0');
		ELSE	
			ShiftRows_Out <= 	ShiftRows_In(127 downto 120) 	&
									ShiftRows_In(87 downto 80)		&
									ShiftRows_In(47 downto 40)		&
									ShiftRows_In(7 downto 0)		&
									
									ShiftRows_In(95 downto 88)		&
									ShiftRows_In(55 downto 48)		&
									ShiftRows_In(15 downto 8)		&
									ShiftRows_In(103 downto 96)	&

									ShiftRows_In(63 downto 56)		&
									ShiftRows_In(23 downto 16)		&
									ShiftRows_In(111 downto 104)	&
									ShiftRows_In(71 downto 64)		&
									
									ShiftRows_In(31 downto 24)		&
									ShiftRows_In(119 downto 112)	&
									ShiftRows_In(79 downto 72)		&
									ShiftRows_In(39 downto 32)		;
		END IF;							
	END IF;
END PROCESS;	

end Behavioral;

