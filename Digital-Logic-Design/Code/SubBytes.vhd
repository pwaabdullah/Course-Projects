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
use work.AES_CONSTANTS.all;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SubBytes is
    Port ( SubBytes_IN : in  STD_LOGIC_VECTOR (127 downto 0);
           SubBytes_OUT : out  STD_LOGIC_VECTOR (127 downto 0);
           SYS_CLK,RST : in  STD_LOGIC);
end SubBytes;

architecture Behavioral of SubBytes is
SIGNAL SUB_BYTES_BUF : STD_LOGIC_VECTOR (127 downto 0) := (OTHERS => '0');
begin
SBOX_BYTE_SUBSTITUTION : PROCESS(SYS_CLK)
begin
	IF (SYS_CLK'event AND SYS_CLK ='1') then
		IF RST = '1' then
			SubBytes_OUT <= (OTHERS => '0');
		ELSE	
			SubBytes_OUT <= SUB_BYTES_BUF; 
		END IF;	
	END IF;
END PROCESS;	

SUB_ARRAY :  For i in 0 to 15 generate
      begin
			SUB_BYTES_BUF((((i+1)*8)-1) downto(i*8)) <= SBOX(conv_integer(SubBytes_IN((((i+1)*8)-1) downto(i*8)))); 
		end generate;

end Behavioral;

