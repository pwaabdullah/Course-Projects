----------------------------------------------------------------------------------
-- Company: KFUPM
-- Student Name: Abdullah Al Mamun
-- Student Id: 201403680
-- Create Date:    17:44:53 02/11/2015 
-- Design Name: 
-- Module Name:    SubBytes - Behavioral 
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

entity AddRoundKey is
    Port ( Data_IN : in  STD_LOGIC_VECTOR (127 downto 0);
           Key_IN : in  STD_LOGIC_VECTOR (127 downto 0);
           Data_OUT : out  STD_LOGIC_VECTOR (127 downto 0);
           SYS_CLK,RST : in  STD_LOGIC);
end AddRoundKey;

architecture Behavioral of AddRoundKey is

begin
XOR_PARTIALKEY_WITH_PLAINTEXT : PROCESS(SYS_CLK)
begin
	IF (SYS_CLK'event AND SYS_CLK ='1') then
		IF RST = '1' then
			Data_OUT <= (OTHERS => '0');
		ELSE	
			Data_OUT <= DATA_IN XOR KEY_IN;
		END IF;	
	END IF;
END PROCESS;	

end Behavioral;

