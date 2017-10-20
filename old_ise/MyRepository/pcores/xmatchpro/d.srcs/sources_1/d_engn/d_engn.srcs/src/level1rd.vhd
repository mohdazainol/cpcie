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

---------------------------------
--  ENTITY       = LEVEL1      --
--  version      = 2.0         --
--  last update  = 1/05/00     --
--  author       = Jose Nunez  --
---------------------------------


-- FUNCTION
--  Top level of the hierarchy.
--  This unit does not include a memory interface


--  PIN LIST
--  START        = indicates start of a compress or decompress operation
--  STOP         = forces the end of the current operation
--  COMPRESS     = selects compression mode
--  DECOMPRESS   = selects decompression mode
--  U_BS_IN      = 15 bits maximum block size 32K. size of the block to be compressed
--  C_BS_INOUT   = 16 bits size of the compressed block. compression read the size of the compressed block. decompresssion input the size of the compressed block. buffers stop when is reached. optional system can non-grant the bus to indicate the same. 
--  CLK          = master clock
--  CLEAR_EXT    = asynchronous reset generated externally
--  CLEAR 	     = asynchronous reset generated by the csm
--  U_DATAIN     = data to be compressed
--  C_DATAIN     = data to be decompressed
--  U_DATAOUT    = decompressed data
--  C_DATAOUT    = compressed data
--  ADDR_EN      = enable address tri-states
--  CDATA_EN     = enable compressed data tri-state outputs
--  UDATA_EN     = enable uncompressed data tri-state outputs
--  FINISHED     = signal of finished operation
--  COMPRESSING  = compression mode active
--  FLUSHING     = flush active
--  DECOMPRESSING = decompression active
--  DISALIGNED   = bytes in block is not a multiple of 4 


library ieee,std;
use ieee.std_logic_1164.all;
-- use std.textio.all;

entity level1rd is
port
(
	CS : in std_logic;
	RW : in std_logic;
	ADDRESS: in std_logic_vector(1 downto 0);
--===========================================================================================
--	CONTROL : inout std_logic_vector(31 downto 0);
	CONTROL_IN : in std_logic_vector (31 downto 0);
	CONTROL_OUT: out std_logic_vector (31 downto 0);
--===========================================================================================
	CLK : in std_logic ;
	CLEAR: in std_logic;
	BUS_ACKNOWLEDGE_C : in std_logic;
	BUS_ACKNOWLEDGE_U : in std_logic;
   WAIT_C : in std_logic;
  WAIT_U : in std_logic;
	C_DATA_VALID : in std_logic;
	START_C : in std_logic;
	TEST_MODE : in std_logic;
	FINISHED_C : in std_logic;
	C_DATAIN : in std_logic_vector(31 downto 0);
	U_DATAOUT : out std_logic_vector(31 downto 0);
	FINISHED : out std_logic;
	FLUSHING : out std_logic;
	DECOMPRESSING : out std_logic;
	U_DATA_VALID : out std_logic;
	DECODING_OVERFLOW : out std_logic;
	CRC_OUT : out std_logic_vector(31 downto 0);
	BUS_REQUEST_C : out std_logic;
  OVERFLOW_CONTROL_DECODING_BUFFER : out std_logic;
	BUS_REQUEST_U : out std_logic
);
end level1rd;


architecture level1_1 of level1rd is

-- these are  the components that form level1

component OUT_REGISTER
        port(
            DIN : in std_logic_vector(31 downto 0);
            CLEAR : in std_logic;
			RESET : in std_logic;
			U_DATA_VALID_IN : in std_logic;
			FINISHED_IN : in std_logic;
		    CLK : in std_logic;
	  	    U_DATA_VALID_OUT : out std_logic;
			FINISHED_OUT : out std_logic;
            QOUT : out  std_logic_vector(31 downto 0)
        );

end component;

component CRC_UNIT_D_32
	port(DIN : in std_logic_vector(31 downto 0);
		 ENABLE : in std_logic;
		 CLK : in std_logic;
		 RESET : in std_logic;
		 CLEAR : in std_logic;
		 CRC_OUT : out std_logic_vector(31 downto 0)
	   	);
end component;


component OUTPUT_BUFFER_32_32
port
(
	FORCE_STOP : in std_logic;
	START_D: in std_logic;
	START_C: in std_logic;
	WRITE : in std_logic;
	FINISHED : in std_logic;
  WAITN : in std_logic;
	DATA_IN_32 : in std_logic_vector(31 downto 0);
	THRESHOLD : in std_logic_vector(7 downto 0);
	BUS_ACKNOWLEDGE : in std_logic;
	CLEAR : in std_logic ;
	CLK : in std_logic ;
	FLUSHING : out std_logic;
	FINISHED_FLUSHING : out std_logic;
	OVERFLOW_DETECTED : out std_logic;
	DATA_OUT_32: out std_logic_vector(31 downto 0);
	READY : out std_logic;
  OVERFLOW_CONTROL : out std_logic;
	BUS_REQUEST : out std_logic
);
end component;


component ASSEMBLING_UNIT
port
(
	ENABLE: in std_logic;
	DATA_IN_32 : in std_logic_vector(31 downto 0);
	CLEAR : in std_logic ;
	RESET : in std_logic;
	CLK : in std_logic ;
	MASK : in std_logic_vector(3 downto 0);
	WRITE : out std_logic;
	DATA_OUT_32: out std_logic_vector(31 downto 0)
);
end  component;

component REG_FILE_D
port
(
        DIN : in std_logic_vector(31 downto 0);
	  	ADDRESS : in std_logic_vector(1 downto 0);
		CRC_IN : in std_logic_vector(31 downto 0);
		LOAD_CRC : in std_logic;
        CLEAR_CR : in std_logic;
	    RW : in std_logic;
        ENABLE : in std_logic;
        CLEAR : in std_logic;
        CLK : in std_logic;
	    DOUT : out std_logic_vector(31 downto 0);
	    C_BS_OUT : out std_logic_vector(31 downto 0);
	    U_BS_OUT : out std_logic_vector(31 downto 0);
		CRC_OUT : out std_logic_vector(31 downto 0);
	    START_D : out std_logic;
	    STOP :out std_logic;
	    THRESHOLD_LEVEL : out std_logic_vector(7 downto 0)

);
end component;



component C_BS_COUNTER_D
port
(
	C_BS_IN : in std_logic_vector(31 downto 0);
 	DECOMPRESS : in std_logic;
	CLEAR : in std_logic;
	CLEAR_COUNTER :  in std_logic;
	CLK : in std_logic;
	ENABLE_D : in std_logic;
	ALL_C_DATA : out std_logic;
	C_BS_OUT : out std_logic_vector(31 downto 0)
);

end component;


component DECODING_BUFFER_32_64_2
port
(
  FORCE_STOP : in std_logic;
	START_D : in std_logic;
	START_C : in std_logic;
	FINISHED_D : in std_logic;
	FINISHED_C : in std_logic;
	UNDERFLOW : in std_logic;
	DATA_IN_32 : in std_logic_vector(31 downto 0);
	THRESHOLD_LEVEL : in std_logic_vector(9 downto 0);
	BUS_ACKNOWLEDGE : in std_logic;
	C_DATA_VALID : in std_logic;
  WAITN : in std_logic;
	CLEAR : in std_logic ;
	CLK : in std_logic ;
	DATA_OUT_64: out std_logic_vector(63 downto 0);
	UNDERFLOW_DETECTED : out std_logic;
	FINISH : out std_logic;
	START_ENGINE : out std_logic;
  OVERFLOW_CONTROL : out std_logic;
	BUS_REQUEST : out std_logic
);
end component;


component csm_d
port
(
	START_C : in std_logic; -- for test mode
	START_D : in std_logic;
	START_D_ENGINE : in std_logic;
	STOP : in std_logic ;
	END_OF_BLOCK : in std_logic ;
	CLK : in std_logic;
	CLEAR: in std_logic;
	DECOMP : out std_logic ;
	FINISH : out std_logic ;
	MOVE_ENABLE : out std_logic ;
	RESET : out std_logic 
);
end component;


component BSL_TC_2_D 
port
(
      BLOCK_SIZE : in std_logic_vector(31 downto 0) ;
      INC : in std_logic ;
      CLEAR : in std_logic ;
	  RESET : in std_logic;
      CLK : in std_logic ;
      EO_BLOCK : out std_logic ;
      FINISH_D_BUFFERS : out std_logic

);

end component;


component level2_4d_pbc
port(
        CLK : in std_logic;
        RESET : in std_logic;
    	CLEAR : in std_logic;   	 
        DECOMP : in std_logic;
        MOVE_ENABLE : in std_logic;
	  DECODING_UNDERFLOW : in std_logic;
	  FINISH : in std_logic;	
      C_DATAIN : in std_logic_vector(63 downto 0);
    U_DATAOUT : out std_logic_vector(31 downto 0);
	MASK : out std_logic_vector(3 downto 0);
	U_DATA_VALID : out std_logic ;
   OVERFLOW_CONTROL : in std_logic;
	UNDERFLOW : out std_logic
    );
end component;


signal  FINISHED_INT : std_logic;
signal UNDERFLOW_INT : std_logic;
signal  MOVE_ENABLE: std_logic;

signal  DECOMP_INT: std_logic;
signal  LOAD_BS: std_logic;
signal  INC_TC: std_logic;
signal  RESET: std_logic;
signal  EO_BLOCK: std_logic;
signal  STOP_INT: std_logic;



signal  START_D_INT : std_logic;
signal START_D_INT_BUFFERS : std_logic; -- to start the decompression engine

signal  LATCHED_BS: std_logic_vector(31 downto 0);

signal C_DATAIN_INT : std_logic_vector(63 downto 0);
signal U_DATAOUT_INT : std_logic_vector(31 downto 0);
signal U_DATAOUT_BUFFER : std_logic_vector(31 downto 0);
signal U_DATAOUT_AUX : std_logic_vector(31 downto 0);

signal U_DATAOUT_REG: std_logic_vector(31 downto 0);

signal ENABLE_READ : std_logic;


signal BUS_REQUEST_DECODING : std_logic;




signal OVERFLOW_DETECTED_DECODING : std_logic;
signal UNDERFLOW_DETECTED_DECODING : std_logic;

signal THRESHOLD_LEVEL : std_logic_vector(7 downto 0);
signal THRESHOLD_LEVEL_FIXED : std_logic_vector(9 downto 0);


signal U_DATA_VALID_INT : std_logic;
signal U_DATA_VALID_REG : std_logic;
signal U_DATA_VALID_AUX:  std_logic;

signal MASK_INT : std_logic_vector(3 downto 0);
signal WRITE_INT : std_logic;


signal FINISH_D_BUFFERS : std_logic;
signal FINISHED_BUFFER_DECODING : std_logic;

signal FINISHED_AUX : std_logic;

signal ALL_C_DATA : std_logic;
signal BUS_ACKNOWLEDGE_AUX : std_logic;

signal C_BS_INT : std_logic_vector(31 downto 0);

signal C_BS_OUT : std_logic_vector(31 downto 0);

signal CONTROL_AUX : std_logic_vector(31 downto 0);

signal CLEAR_COMMAND : std_logic; -- to reset the command register

signal ENABLE_D_COUNT : std_logic;  -- count compressed data during decompression

signal CRC_CODE : std_logic_vector(31 downto 0);
signal ENABLE_CRC : std_logic;
signal DATA_CRC : std_logic_vector(31 downto 0);
signal ENABLE_ASSEMBLE : std_logic; -- stop assembling when block recovered
signal FINISHED_BUFFER : std_logic;
signal BUS_ACKNOWLEDGE_U_AUX : std_logic;
signal BUS_REQUEST_U_AUX : std_logic;
signal THRESHOLD_LEVEL_AUX : std_logic_vector(7 downto 0);
signal OVERFLOW_CONTROL : std_logic;



begin


OUT_REGISTER_1: OUT_REGISTER
        port map(
            DIN =>U_DATAOUT_REG,
            CLEAR =>CLEAR,
			RESET =>RESET,
			U_DATA_VALID_IN =>U_DATA_VALID_REG,
			FINISHED_IN => FINISHED_BUFFER,
		    CLK =>CLK,
	  	    U_DATA_VALID_OUT =>U_DATA_VALID_AUX,
			FINISHED_OUT => FINISHED,
            QOUT =>   U_DATAOUT_AUX
       );


CRC_UNIT_1: CRC_UNIT_D_32
	port map(DIN =>DATA_CRC,
		 ENABLE =>ENABLE_CRC,
		 CLK => CLK,
		 RESET => FINISHED_BUFFER,
		 CLEAR => CLEAR,
		 CRC_OUT => CRC_CODE
	   	);

DATA_CRC <= U_DATAOUT_REG; 
ENABLE_CRC <= not(U_DATA_VALID_REG);

OUTPUT_BUFFER_32_32_1 : OUTPUT_BUFFER_32_32
port map
( 
	FORCE_STOP => STOP_INT, 
	START_D =>START_D_INT,
	START_C => START_C,
	WRITE =>WRITE_INT,
	FINISHED =>FINISHED_INT,
  WAITN => WAIT_U,
	DATA_IN_32 =>U_DATAOUT_BUFFER,
	THRESHOLD =>THRESHOLD_LEVEL_AUX,
	BUS_ACKNOWLEDGE =>BUS_ACKNOWLEDGE_U_AUX,
	CLEAR =>CLEAR,
	CLK =>CLK,
	FLUSHING =>FLUSHING,
	FINISHED_FLUSHING =>FINISHED_BUFFER,
	OVERFLOW_DETECTED => OVERFLOW_DETECTED_DECODING,
	DATA_OUT_32 =>U_DATAOUT_REG,
	READY => U_DATA_VALID_REG,
  OVERFLOW_CONTROL => OVERFLOW_CONTROL,
	BUS_REQUEST =>BUS_REQUEST_U_AUX
);



ASSEMBLING_UNIT_1: ASSEMBLING_UNIT
port map (
	ENABLE => ENABLE_ASSEMBLE,
	DATA_IN_32 => U_DATAOUT_INT,
	CLEAR =>CLEAR,
	RESET => RESET,
	CLK =>CLK,
	MASK =>MASK_INT,
	WRITE =>WRITE_INT,
	DATA_OUT_32 => U_DATAOUT_BUFFER
);


ENABLE_ASSEMBLE <= U_DATA_VALID_INT;
				 

level2_4_1 : level2_4d_pbc port map (CLK => CLK,
				RESET => RESET,
				CLEAR => CLEAR,
				DECOMP => DECOMP_INT,
				MOVE_ENABLE => MOVE_ENABLE,
				DECODING_UNDERFLOW => UNDERFLOW_DETECTED_DECODING, -- to stop the decompression engine
				FINISH => FINISHED_INT,
				C_DATAIN => C_DATAIN_INT,
				U_DATAOUT => U_DATAOUT_INT,
				MASK => MASK_INT,
				U_DATA_VALID => U_DATA_VALID_INT,
          OVERFLOW_CONTROL => OVERFLOW_CONTROL,
				UNDERFLOW => UNDERFLOW_INT
	);





csm_1 : csm_d port map (
    START_C => START_C,
	START_D => START_D_INT,
	START_D_ENGINE => START_D_INT_BUFFERS,
	STOP => STOP_INT,
	END_OF_BLOCK => EO_BLOCK,
	CLK => CLK,
	CLEAR => CLEAR,
	DECOMP => DECOMP_INT,
	FINISH => FINISHED_INT,
	MOVE_ENABLE => MOVE_ENABLE,
	RESET => RESET
);



-- if decoding underflow active do not increment the counter


BSL_TC_1: BSL_TC_2_D port map (
      BLOCK_SIZE => LATCHED_BS,
      INC => WRITE_INT,
	  CLEAR => CLEAR,
      RESET => RESET,
      CLK => CLK,
      EO_BLOCK => EO_BLOCK,
   	  FINISH_D_BUFFERS => FINISH_D_BUFFERS
);

  
REG_FILE_1 : REG_FILE_D
port map
(
        DIN => CONTROL_AUX,	
        ADDRESS => ADDRESS,
		CRC_IN => CRC_CODE,
		LOAD_CRC => FINISHED_BUFFER,
  	    CLEAR_CR => CLEAR_COMMAND,    -- reset the comand register to avoid restart.
	    RW => RW,
	    ENABLE =>CS,
        CLEAR =>CLEAR,
        CLK =>CLK,
	    DOUT => CONTROL_OUT,
    	C_BS_OUT => C_BS_INT,
	    U_BS_OUT => LATCHED_BS,
		CRC_OUT => CRC_OUT,
	    START_D => START_D_INT,
	    STOP => STOP_INT,
	    THRESHOLD_LEVEL => THRESHOLD_LEVEL 
);




C_BS_COUNTER_1 : C_BS_COUNTER_D
port map
(
	C_BS_IN => C_BS_INT,
	DECOMPRESS => START_D_INT,
	CLEAR_COUNTER => FINISHED_AUX,
	CLEAR => CLEAR,
	CLK => CLK,
	ENABLE_D => ENABLE_D_COUNT,
	ALL_C_DATA => ALL_C_DATA,
	C_BS_OUT => C_BS_OUT
);



DECODING_BUFFER : DECODING_BUFFER_32_64_2
port map
(
  FORCE_STOP => STOP_INT,
	START_D => START_D_INT,
	START_C => START_C,
	FINISHED_D => FINISH_D_BUFFERS,
    FINISHED_C => FINISHED_C,
	UNDERFLOW  => UNDERFLOW_INT,
	DATA_IN_32 => C_DATAIN,
	THRESHOLD_LEVEL => THRESHOLD_LEVEL_FIXED,
	BUS_ACKNOWLEDGE => BUS_ACKNOWLEDGE_AUX,
	C_DATA_VALID => C_DATA_VALID,
  WAITN => WAIT_C,
	CLEAR => CLEAR,
	CLK => CLK,
	DATA_OUT_64 => C_DATAIN_INT,
	UNDERFLOW_DETECTED => UNDERFLOW_DETECTED_DECODING,
	FINISH => FINISHED_BUFFER_DECODING,
	START_ENGINE => START_D_INT_BUFFERS,
  OVERFLOW_CONTROL => OVERFLOW_CONTROL_DECODING_BUFFER,
	BUS_REQUEST => BUS_REQUEST_DECODING
);	

THRESHOLD_LEVEL_FIXED <= "0000000001";  -- buffer present in the ouput. Activate the input buffer inmediatly

-- careful I change this for the PCI implementation
-- U_DATAOUT <= To_X01Z(U_DATAOUT_AUX) when BUS_ACKNOWLEDGE_U = '0' and TEST_MODE = '0' else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
U_DATAOUT <= To_X01Z(U_DATAOUT_AUX); 
DECOMPRESSING <= DECOMP_INT;
BUS_REQUEST_C <= BUS_REQUEST_DECODING;
FINISHED_AUX <= DECOMP_INT or FINISHED_INT;

CLEAR_COMMAND <= DECOMP_INT or FINISHED_INT; -- clear the command register
U_DATA_VALID <= U_DATA_VALID_AUX when TEST_MODE = '0' else '1'; -- valid at zero


DECODING_OVERFLOW <= OVERFLOW_DETECTED_DECODING;
BUS_ACKNOWLEDGE_AUX  <= BUS_ACKNOWLEDGE_C or ALL_C_DATA;
CONTROL_AUX <= CONTROL_IN;

BUS_ACKNOWLEDGE_U_AUX <= BUS_ACKNOWLEDGE_U when TEST_MODE = '0' else '0'; -- always acknowledge in test mode 


ENABLE_D_COUNT <= BUS_ACKNOWLEDGE_C or BUS_REQUEST_DECODING; -- both at zero

BUS_REQUEST_U <= BUS_REQUEST_U_AUX when TEST_MODE = '0' else '1';   -- never request
THRESHOLD_LEVEL_AUX <= THRESHOLD_LEVEL when TEST_MODE = '0' else "00001000"; 

end level1_1;