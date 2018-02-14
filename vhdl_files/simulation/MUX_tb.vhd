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
-- MUX TESTBENCH
----------------------------------------------------------------------------------
-- Checks the correct operation of the MUX using a textfile (and also some fixed 
-- tests). The file includes the inputs and how the output should look like. 
-- The output of the file is compared with the output of the design.
-- In the first line of the file there are two integers indicating the number
-- of select lines and the bus size.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Change parameters for simulation
-- for MMux: bus size (12), sel size (2)
-- for AMux: bus size (8), sel size (1)
-- filename
package mux_sim_parameters is
    constant c_bus_size : positive := 8;
    constant c_sel_size : positive := 1;
    constant c_filename_input : STRING := "amux_test.txt"; 
    constant c_filename_log : STRING := "amux_log.txt";
end package mux_sim_parameters;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

library work;
use work.datatypes.all;
use work.mux_sim_parameters.all;


entity MUX_tb is
    Generic(
      g_bus_size : positive := c_bus_size;
      g_sel_size : positive := c_sel_size 
    );
end MUX_tb;



architecture testbench of MUX_tb is

    component MUX
      Generic ( 
        g_bus_size : positive;
        g_sel_size : positive 
      );
      Port ( 
        i_SELECT : in STD_LOGIC_VECTOR (g_sel_size-1 downto 0);
        i_INPUTS : in t_MUX_ARRAY 
            (0 to 2**g_sel_size-1, g_bus_size-1 downto 0);
        o_OUTPUT : out STD_LOGIC_VECTOR (g_bus_size-1 downto 0)
      );
    end component;

    signal r_SELECT: STD_LOGIC_VECTOR (g_sel_size-1 downto 0) := (others => '0');
    signal r_INPUTS: t_MUX_ARRAY (0 to 2**g_sel_size-1, g_bus_size-1 downto 0) 
        := (others => (others => '1'));
    signal w_output: STD_LOGIC_VECTOR (g_bus_size-1 downto 0);

    file file_check : TEXT; -- the input text file
    file file_log : TEXT;   -- log outputs with error info

begin

    uut: MUX 
      generic map ( 
        g_bus_size => g_bus_size,
        g_sel_size => g_sel_size 
      )
      port map ( 
        i_SELECT => r_SELECT,
        i_INPUTS => r_INPUTS,
        o_OUTPUT => w_output 
      );
                         

    PROC_stim: process
      variable v_line_pointer_read : LINE;
      variable v_line_pointer_write : LINE;
      variable v_fstatus : FILE_OPEN_STATUS;
      variable v_line_count : NATURAL := 2;      
      
      variable v_input : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
      variable v_output : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
      variable v_sel : STD_LOGIC_VECTOR (g_sel_size-1 downto 0);
    
      variable v_sel_size_check : POSITIVE;
      variable v_bus_size_check : POSITIVE;
 
    begin
      file_open(v_fstatus, file_check, "..\..\..\Testbench_Files\MUX\" &
          c_filename_input, READ_MODE);  
          
      assert(v_fstatus /= name_error)
      report("Input file does not exist!")
      severity failure;
    
      file_open(v_fstatus, file_log, "..\..\..\Testbench_Files\MUX\" &
          c_filename_log, WRITE_MODE); 
      assert(v_fstatus /= name_error)
      report("Log file could not be created!")
      severity failure;
    
      readline(file_check, v_line_pointer_read);
      read(v_line_pointer_read, v_sel_size_check);
      read(v_line_pointer_read, v_bus_size_check); 
    
      assert(v_sel_size_check =  g_sel_size)
      report("Wrong select size! Failure in line 1.")
      severity failure;
    
      assert(v_bus_size_check =  g_bus_size)
      report("Wrong bus size! Failure in line 1.")
      severity failure;
      
      
      report("Started!");
    
      write(v_line_pointer_write, STRING'("Output log for "));
      write(v_line_pointer_write, c_filename_input);
      writeline(file_log, v_line_pointer_write);
    
      while not endfile(file_check) loop
        readline(file_check, v_line_pointer_read);
      
        for i in 0 to 2**g_sel_size-1 loop
          read(v_line_pointer_read, v_input);
        
          for j in 0 to g_bus_size-1 loop
            r_INPUTS(i,j) <= v_input(j);
          end loop;
        end loop;  
      
        read(v_line_pointer_read, v_sel);
        r_SELECT <= v_sel;

        wait for 10 ns;
      
        read(v_line_pointer_read, v_output);
      
        assert(w_output = v_output)
        report ("Failure in line " & integer'image(v_line_count) & ".")
        severity error;
      
        -- Log outputs
        -- The line of the output corresponds with the line of the input file.
        write(v_line_pointer_write, w_output);
        
        if(w_output /= v_output) then
          write(v_line_pointer_write, STRING'(" ERROR"));
        else
          write(v_line_pointer_write, STRING'(" OK"));
        end if;
        writeline(file_log, v_line_pointer_write);
    
        v_line_count := v_line_count + 1;
    
      end loop;
    
      file_close(file_check);  
      file_close(file_log);  
      
      report("Finished! Checked " & integer'image(v_line_count - 2) & " lines.");
      wait;
    end process PROC_stim;


end testbench;
