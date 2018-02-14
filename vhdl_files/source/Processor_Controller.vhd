-- BSD 3-Clause License
-- 
-- Copyright (c) 2018, Bernhard Vacarescu
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
-- 
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
-- 
-- * Neither the name of the copyright holder nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


----------------------------------------------------------------------------------
-- PROCESSOR CONTROLLER
----------------------------------------------------------------------------------
-- included part(s): 
--    PROCESSOR, SEVEN SEGMENT CONTROL (SEGMENT DRIVER and  SEVEN SEGMENT) 
----------------------------------------------------------------------------------
-- Used for hardware implementation. It directly includes the RAM (which is
-- actually intended to be externally).
-- To check the functionality without special debugging techniques, via 
-- external switches the RAM can be addressed, and using two 7-segment displays 
-- its memory content at this memory location is displayed in hexadecimal number
-- format.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.datatypes.all;
use work.functions.all;


entity Processor_Controller is
    Generic ( 
      -- RAM file containing the program that should be executed
      g_ram_filename : string := "RAM_MEM_1.txt"; 
      -- maximum: 16 bit
      -- for faster synthesis and implementation and if no big memory
      -- needed 12 bit optimal (attention: SP still initialized with 0xFFFF)
      g_ram_bit_size : positive := 12; 
      -- for about 13 ms debounce at 10 MHz clock: 17 bit
      -- to really "feel" debounce in hardware: 20 bit used (about 100 ms debounce)
      g_debounce_counter_bit_size : positive := 20;
      -- used for displaying the digits of the seven segment displays alternating.
      -- for 10 MHz clock 15 bit optimal
      g_LED_counter_bit_size : positive := 15 
    );
    Port ( 
      i_CLK : in STD_LOGIC;
      i_RESET : in STD_LOGIC;
      i_INTERRUPT : in STD_LOGIC_VECTOR (1 to 2);
      i_SEGMENT_ADDRESS : in STD_LOGIC_VECTOR (15 downto 0);
      -- encodes which segment should be controlled
      o_SEGMENT : out STD_LOGIC_VECTOR (3 downto 0); 
      -- encodes the digit which should be displayed
      o_DIGIT_ENCODED : out STD_LOGIC_VECTOR (6 downto 0)
     );
end Processor_Controller;



architecture Mixed of Processor_Controller is

    signal w_address : STD_LOGIC_VECTOR (15 downto 0);
    signal w_rd : STD_LOGIC;
    signal w_wr : STD_LOGIC;
    signal w_clk_memory : STD_LOGIC;
    signal w_main_clk : STD_LOGIC;
    
    signal r_DATA : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal rw_DATA_LINE : STD_LOGIC_VECTOR (7 downto 0) := (others => 'Z');

    -- stores content that should be displayed on the 7-segment display
    signal r_DISPLAY_DATA : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
    signal w_digit : STD_LOGIC_VECTOR (3 downto 0);

    signal r_RAM : t_RAM (0 to 2**g_ram_bit_size-1) := 
        initRam("..\..\..\RAM_File\" & g_ram_filename, 2**g_ram_bit_size-1);
        
    attribute ram_style : string;   
    attribute ram_style of r_RAM : signal is "block";
    
begin

    Processor_inst : entity work.Processor
      generic map (
        g_debounce_counter_bit_size => g_debounce_counter_bit_size 
      )
      port map ( 
        i_CLK => i_CLK,
        i_RESET_PIN => i_RESET, 
        i_INTERRUPT => i_INTERRUPT,
        o_ADDRESS => w_address,
        o_RD => w_rd,
        o_WR => w_wr,
        io_DATA => rw_DATA_LINE, 
        o_CLK_MEMORY => w_clk_memory,
        o_CLK_MAIN => w_main_clk
      );
      
    Segment_Driver : entity work.Segment_Driver
      generic map (
        g_counter_bit_size => g_LED_counter_bit_size
      )
      port map ( 
        i_DIGIT3 => "0000",
        i_DIGIT2 => "0000",
        i_DIGIT1 => r_DISPLAY_DATA(7 downto 4),
        i_DIGIT0 => r_DISPLAY_DATA(3 downto 0),
        i_ACTIVE_DIGITS_MASK => "1100", -- two right 7-segment displays are active
        i_CLK => w_main_clk,
        o_digit => w_digit,
        o_segment => o_SEGMENT 
      );         
               

    LED_inst: entity work.Seven_Segment
      port map ( 
       i_digit => w_digit,
       o_segments => o_DIGIT_ENCODED
      ); 


    PROC_memory_processor: process (w_clk_memory)
    begin
      if rising_edge(w_clk_memory) then
        if w_wr = '1' then
          r_RAM(to_integer(unsigned(w_address))) <= rw_DATA_LINE;    
        end if;
        -- output updated at every rising edge
        -- no problem, as data by processor only used when needed
        r_DATA <= r_RAM(to_integer(unsigned((w_address))));    
      end if;
    end process PROC_memory_processor; 
    
    
    rw_DATA_LINE <= r_DATA when w_rd = '1' else (others => 'Z');    
    
    
    PROC_memory_LED: process (w_clk_memory)
    begin
      if rising_edge(w_clk_memory) then
        r_DISPLAY_DATA <= 
            r_RAM(to_integer(unsigned(i_SEGMENT_ADDRESS)));
      end if;
    end process PROC_memory_LED; 

end Mixed;