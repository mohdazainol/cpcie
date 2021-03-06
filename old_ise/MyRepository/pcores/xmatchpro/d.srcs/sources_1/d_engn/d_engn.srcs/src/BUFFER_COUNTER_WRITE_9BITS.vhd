--This library is free software; you can redistribute it and/or
--modify it under the terms of the GNU Lesser General Public
--License as published by the Free Software Foundation; either
--version 2.1 of the License, or (at your option) any later version.

--This library is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--Lesser General Public License for more details.

--You should have received a copy of the GNU Lesser General Public
--License along with this library; if not, write to the Free Software
--Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

-- e_mail : j.l.nunez-yanez@byacom.co.uk

-------------------------------------------------
--  ENTITY       = BUFFER_COUNTER_WRITE        --
--  version      = 1.0                         --
--  last update  = 30/5/00                     --
--  author       = Jose Nunez                  --
-------------------------------------------------


-- FUNCTION
-- 8 bit counter for the read and write on dual port ram buffers


--  PIN LIST
--  ENABLE = enable count 
--  CLEAR = asyncronus clear of the counter
--  CLK   = master clock
--  COUNT = count output


library dzx;
use dzx.bit_arith.all;
use dzx.bit_utils.all; 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity BUFFER_COUNTER_WRITE_9BITS is

port (  ENABLE : in std_logic;
		SHORT : in std_logic; -- only write 32 bits
	  CLEAR : in std_logic;
	  CLEAR_COUNTERS : in std_logic;
	  CLK : in std_logic;
	  COUNT : out std_logic_vector(9 downto 0)
     );

end BUFFER_COUNTER_WRITE_9BITS;

architecture STRUCTURAL of BUFFER_COUNTER_WRITE_9BITS is

signal COUNT_AUX : std_logic_vector(9 downto 0);


begin


COUNTING : process (CLK,CLEAR,CLEAR_COUNTERS,ENABLE)

begin
    	-- asynchronous RESET signal forces all outputs LOW
      if (CLEAR = '0') then
	    COUNT_AUX <= "0000000000";
	    -- check for +ve clock edge
	  elsif ((CLK'event) and (CLK = '1')) then
		   if(CLEAR_COUNTERS = '1') then
			     COUNT_AUX <= "0000000000";
	         elsif( ENABLE = '1') then
								if (SHORT = '1') then
	    	          			 COUNT_AUX <= COUNT_AUX+"0000000010";
							   else
	    	          			 COUNT_AUX <= COUNT_AUX+"0000000001";  -- short enable at zero
								end if;
			 else
			     COUNT_AUX <= COUNT_AUX;
			 end if;
	 end if;
	 
end process COUNTING;
 
COUNT <= COUNT_AUX;

end STRUCTURAL;