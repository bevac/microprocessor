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
-- Processor Controller Testbench
----------------------------------------------------------------------------------
-- Reads in a RAM content file that includes a program that should be executed.
-- An extra file provides an interrupt routine that should be performed (like
-- also used for testing the processor module).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Change parameter for simulation
package processor_controller_sim_parameters is
    constant c_pre_filename : STRING := "controller_1";
end package processor_controller_sim_parameters;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

library work;
use work.processor_controller_sim_parameters.all;
use work.datatypes.all;
use work.functions.all;


entity Processor_Controller_tb is

end Processor_Controller_tb;



architecture testbench of Processor_Controller_tb is
    
    component Processor_Controller
      Generic ( 
        g_ram_filename : string := "RAM_MEM_1.txt"; 
        -- for simulation 16 bit used
        g_ram_bit_size : positive := 16; 
        -- for simulation just 4 bit used, otherwise long simulation time needed
        g_debounce_counter_bit_size : positive := 4;
        -- for simulation 2 bit used
        g_LED_counter_bit_size : positive := 2 
      );
      Port ( 
        i_CLK : in STD_LOGIC;
        i_RESET : in STD_LOGIC;
        i_INTERRUPT : in STD_LOGIC_VECTOR (1 to 2);
        i_SEGMENT_ADDRESS : in STD_LOGIC_VECTOR (15 downto 0);
        o_SEGMENT : out STD_LOGIC_VECTOR (3 downto 0); 
        o_DIGIT_ENCODED : out STD_LOGIC_VECTOR (6 downto 0)
      );
    end component;
    
    constant c_filename_routine : STRING := c_pre_filename & "_routine.txt";

    file file_routine : TEXT;
 
    signal r_CLK : STD_LOGIC := '0';
    signal r_RESET : STD_LOGIC := '0';
    signal r_INTERRUPT : STD_LOGIC_VECTOR (1 to 2) := "00";
    signal r_SEGMENT_ADDRESS : STD_LOGIC_VECTOR (15 downto 0) 
        := "0000000100000001"; -- address 257
    signal w_segment : STD_LOGIC_VECTOR (3 downto 0); 
    signal w_digit_encoded : STD_LOGIC_VECTOR (6 downto 0);

    alias r_INT1 : STD_LOGIC is r_INTERRUPT(1);
    alias r_INT2 : STD_LOGIC is r_INTERRUPT(2);
    
    signal finished_interrupts : BOOLEAN;

    constant c_clock_period : TIME := 10 ns; -- 100 MHz input

begin

    uut: Processor_Controller
      port map ( 
        i_CLK => r_CLK,
        i_RESET => r_RESET,
        i_INTERRUPT => r_INTERRUPT,
        i_SEGMENT_ADDRESS => r_SEGMENT_ADDRESS,
        o_SEGMENT => w_segment,
        o_DIGIT_ENCODED => w_digit_encoded
      );
                         

    PROC_stim: process
      variable v_line_pointer_read : LINE;
      variable v_fstatus : FILE_OPEN_STATUS;  
      
      variable v_input_string : STRING (1 to 4);
      variable v_input_value : STD_LOGIC;  
      variable v_input_time : TIME;     
    begin

        file_open(v_fstatus, file_routine, 
            "..\..\..\Testbench_Files\Controller\" & c_filename_routine, READ_MODE);    

        assert(v_fstatus /= name_error)
        report("Input file " & c_filename_routine &  " does not exist!")
        severity failure;

      report("Started!");
                    
      while not endfile(file_routine) loop
          
        readline(file_routine, v_line_pointer_read);
        read(v_line_pointer_read, v_input_string);
          
        if v_input_string = "RSET" then
          read(v_line_pointer_read, v_input_value);
          r_RESET <= v_input_value;
        elsif v_input_string = "INT1" then
          read(v_line_pointer_read, v_input_value);
          r_INT1 <= v_input_value;
        elsif v_input_string = "INT2" then
          read(v_line_pointer_read, v_input_value);
          r_INT2 <= v_input_value;
        elsif v_input_string = "WAIT" then
          read(v_line_pointer_read, v_input_time);
          wait for v_input_time;
        end if;
      end loop; 
        
      file_close(file_routine);
      
      -- because of clock generator process only possible way for automatic stop
      assert FALSE
      report "Simulation finished!"
      severity failure; 
      
    end process PROC_stim;
   
    
    PROC_clock: process
    begin    
      wait for 1 ps;
      while TRUE loop       
        wait for c_clock_period/2;
        r_CLK <= '1';
        wait for c_clock_period/2;
        r_CLK <= '0';
      end loop;  
    end process PROC_clock;

end testbench;