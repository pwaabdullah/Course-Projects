----------------------------------------------------------------------------------
-- Company: KFUPM
-- Student Name: Abdullah Al Mamun
-- Student Id: 201403680
-- Create Date:    17:44:53 02/11/2015 
-- Design Name: 
-- Module Name:    MixColumns - Behavioral 
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

entity MixColumns is
    Port ( SYS_CLK,RST : in  STD_LOGIC;
           DATA_IN : in  STD_LOGIC_VECTOR (127 downto 0);
           DATA_OUT : out  STD_LOGIC_VECTOR (127 downto 0));
end MixColumns;

architecture Behavioral of MixColumns is
COMPONENT Column_Matrix_Mul
	PORT(
		SYS_CLK : IN std_logic;
		RST : IN std_logic;
		COLUMN_IN : IN std_logic_vector(31 downto 0);          
		COLUMN_OUT : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

begin

	Column_Matrix_Mul_0: Column_Matrix_Mul PORT MAP(
		SYS_CLK => SYS_CLK,
		RST => RST,
		COLUMN_IN => DATA_IN(127 downto 96),
		COLUMN_OUT => DATA_OUT(127 downto 96)
	);
	
	Column_Matrix_Mul_1 : Column_Matrix_Mul PORT MAP(
		SYS_CLK => SYS_CLK,
		RST => RST,
		COLUMN_IN => DATA_IN(95 downto 64),
		COLUMN_OUT => DATA_OUT(95 downto 64)
	);
	
	Column_Matrix_Mul_2: Column_Matrix_Mul PORT MAP(
		SYS_CLK => SYS_CLK,
		RST => RST,
		COLUMN_IN => DATA_IN(63 downto 32),
		COLUMN_OUT => DATA_OUT(63 downto 32)
	);
	
	Column_Matrix_Mul_3: Column_Matrix_Mul PORT MAP(
		SYS_CLK => SYS_CLK,
		RST => RST,
		COLUMN_IN => DATA_IN(31 downto 0),
		COLUMN_OUT => DATA_OUT(31 downto 0)
	);

end Behavioral;

