----------------------------------------------------------------------------------
-- Company: KFUPM
-- Student Name: Abdullah Al Mamun
-- Student Id: 201403680
-- Create Date:    17:44:53 02/11/2015 
-- Design Name: 
-- Module Name:    KeySchedule - Behavioral 
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

entity Key_Schedule_128 is
    Port ( SYS_CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
	 
				KEY_128 : in  STD_LOGIC_VECTOR (127 downto 0);
				PAR_KEY : out  STD_LOGIC_VECTOR (127 downto 0);
				
				LOAD_KEY : in  STD_LOGIC;
				EXP_KEY : in  STD_LOGIC);
end Key_Schedule_128;

architecture Behavioral of Key_Schedule_128 is
SIGNAL MASTER_KEY : ARRAY4x32 := (X"00000000",X"00000000",X"00000000",X"00000000");
SIGNAL ACTIVE_KEY : ARRAY4x32 := (X"00000000",X"00000000",X"00000000",X"00000000");
SIGNAL KEY_INTRVL : integer range 0 to 15;
SIGNAL ROTWRDSUB : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
SIGNAL STEP_COUNT : integer range 0 to 3;
SIGNAL KEY_COL_0  : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
SIGNAL KEY_COL_1  : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
SIGNAL KEY_COL_2  : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
SIGNAL KEY_COL_3  : STD_LOGIC_VECTOR(31 downto 0) := (OTHERS => '0');
--SIGNAL LOAD_LATCH : STD_LOGIC := '0';
SIGNAL ACT_RCON  : STD_LOGIC_VECTOR(7 downto 0) := (OTHERS => '0');
begin


ROUND_STEP_COUNTER : PROCESS (SYS_CLK,RST,EXP_KEY)
begin
	IF (SYS_CLK'event and SYS_CLK = '1') then
		IF (RST = '1' OR EXP_KEY = '0') then
			STEP_COUNT <= 3;
		ELSIF STEP_COUNT = 3 then
			STEP_COUNT <= 0;
		ELSE
			STEP_COUNT <= STEP_COUNT + 1;
		END IF;
	END IF;
END PROCESS;

MASTER_KEY_REGISTER : PROCESS (SYS_CLK,RST,EXP_KEY)
begin
	IF (SYS_CLK'event and SYS_CLK = '1') then
		IF (RST = '1') then
			MASTER_KEY <= (X"00000000",X"00000000",X"00000000",X"00000000");
		ELSIF (LOAD_KEY = '1' AND EXP_KEY = '0') then
			MASTER_KEY <= (KEY_128(127 downto 96),KEY_128(95 downto 64),KEY_128(63 downto 32),KEY_128(31 downto 0));
		END IF;
	END IF;
END PROCESS;


KEY_PROCESSING_REGISTERS : PROCESS (SYS_CLK,RST,EXP_KEY)
begin
	IF (SYS_CLK'event and SYS_CLK = '1') then
		IF RST = '1'then
			ACTIVE_KEY <= (X"00000000",X"00000000",X"00000000",X"00000000");
			ROTWRDSUB  <= X"00000000";
			KEY_INTRVL <= 0;
			ACT_RCON   <= X"00";			
		ELSIF EXP_KEY = '0' then
			ACTIVE_KEY <= MASTER_KEY;
			ROTWRDSUB  <= X"00000000";
			KEY_INTRVL <= 0;
			ACT_RCON   <= X"00";
			IF (LOAD_KEY = '1') then
				ACTIVE_KEY <= (KEY_128(127 downto 96),KEY_128(95 downto 64),KEY_128(63 downto 32),KEY_128(31 downto 0));
			END IF;	
		ELSIF STEP_COUNT = 3 then
			ACTIVE_KEY <= ACTIVE_KEY;
			ROTWRDSUB  <= 	SBOX(conv_integer(ACTIVE_KEY(3)(23 downto 16))) &
								SBOX(conv_integer(ACTIVE_KEY(3)(15 downto 8))) &
								SBOX(conv_integer(ACTIVE_KEY(3)(7 downto 0))) &
								SBOX(conv_integer(ACTIVE_KEY(3)(31 downto 24)))	;
								
								
			KEY_INTRVL <= KEY_INTRVL;
			ACT_RCON   <= RCON(KEY_INTRVL);	
		ELSIF STEP_COUNT = 0 then
			ACTIVE_KEY <= 	(KEY_COL_0,KEY_COL_1,KEY_COL_2,KEY_COL_3);
			ROTWRDSUB  <= ROTWRDSUB;
			KEY_INTRVL <= KEY_INTRVL + 1;
			ACT_RCON <= ACT_RCON;
		END IF;
	END IF;
END PROCESS;	

KEY_COL_0 <= ACTIVE_KEY(0) XOR ROTWRDSUB XOR (ACT_RCON & X"000000");
KEY_COL_1 <= ACTIVE_KEY(1) XOR KEY_COL_0;
KEY_COL_2 <= ACTIVE_KEY(2) XOR KEY_COL_1;
KEY_COL_3 <= ACTIVE_KEY(3) XOR KEY_COL_2;
PAR_KEY <= ACTIVE_KEY(0) & ACTIVE_KEY(1) & ACTIVE_KEY(2) & ACTIVE_KEY(3);


	

--ROTWRDSUB <= 	SBOX(conv_integer(ACTIVE_KEY(3)(31 downto 24))) &
--					SBOX(conv_integer(ACTIVE_KEY(3)(7 downto 0))) &
--					SBOX(conv_integer(ACTIVE_KEY(3)(15 downto 8))) &
--					SBOX(conv_integer(ACTIVE_KEY(3)(23 downto 16)));
--					
--ACTIVE_KEY(0) <= ACTIVE_KEY(0) XOR ROTWRDSUB XOR (RCON(KEY_INTRVL) & X"000000");
--ACTIVE_KEY(1) <= ACTIVE_KEY(1) XOR ACTIVE_KEY(0);
--ACTIVE_KEY(2) <= ACTIVE_KEY(2) XOR ACTIVE_KEY(1);
--ACTIVE_KEY(3) <= ACTIVE_KEY(3) XOR ACTIVE_KEY(2);



end Behavioral;

