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
-- ALU TESTBENCH
----------------------------------------------------------------------------------
-- Checks the correct operation of the ALU using a textfile. The file includes
-- the inputs and how the output should look like. The output of the file
-- is compared with the output of the design.
-- In the first line of the file there is an integer indicating the bus size.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Edit simulation parameters before simulation
package alu_parameters is
    constant c_bus_size : positive := 8;
    constant c_filename_input : STRING := "alu_test.txt"; 
    constant c_filename_log : STRING := "alu_log.txt";
end package alu_parameters;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

library work;
use work.alu_parameters.all;


entity ALU_tb is
    Generic( 
      g_bus_size : positive := c_bus_size 
    );
end ALU_tb;



architecture testbench of ALU_tb is

    component ALU
        Generic( 
          g_bit : positive := 8
        );
        Port ( 
          i_ALU_A : in STD_LOGIC_VECTOR (g_bit-1 downto 0);
          i_ALU_B : in STD_LOGIC_VECTOR (g_bit-1 downto 0);
          i_SEL : in STD_LOGIC_VECTOR (3 downto 0);
          i_CLK : in STD_LOGIC;
          o_ALU_OUT : out STD_LOGIC_VECTOR (g_bit-1 downto 0);
          o_Z_FLAG : out STD_LOGIC;
          o_N_FLAG : out STD_LOGIC;
          o_V_FLAG : out STD_LOGIC;
          o_C_FLAG : out STD_LOGIC 
        );
    end component;

    signal r_ALU_A : STD_LOGIC_VECTOR (g_bus_size-1 downto 0) := (others => '0');
    signal r_ALU_B : STD_LOGIC_VECTOR (g_bus_size-1 downto 0) := (others => '0');
    signal r_SEL : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    signal r_CLK : STD_LOGIC := '1';
    signal w_alu_out : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
    signal w_z_flag : STD_LOGIC;
    signal w_n_flag : STD_LOGIC;
    signal w_v_flag : STD_LOGIC;
    signal w_c_flag : STD_LOGIC;
  
    file file_check : TEXT; -- the input text file
    file file_log : TEXT; -- log outputs with error info

    signal stop_the_clock: BOOLEAN;

begin

  uut: ALU 
    generic map ( 
      g_bit => g_bus_size
    )
    port map ( 
      i_ALU_A => r_ALU_A, 
      i_ALU_B => r_ALU_B, 
      i_SEL => r_SEL,
      i_CLK => r_CLK, 
      o_ALU_OUT => w_alu_out, 
      o_Z_FLAG => w_z_flag,
      o_N_FLAG => w_n_flag, 
      o_V_FLAG => w_v_flag,
      o_C_FLAG => w_c_flag 
    );


    PROC_stim: process
    
      variable v_line_pointer_read : LINE;
      variable v_line_pointer_write : LINE;
      variable v_fstatus : FILE_OPEN_STATUS;
      variable v_line_count : NATURAL := 2;      
      
      variable v_input_a : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
      variable v_input_b : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
      variable v_select : STD_LOGIC_VECTOR (3 downto 0);
      variable v_output : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
      variable v_z_flag : STD_LOGIC;
      variable v_n_flag : STD_LOGIC;
      variable v_v_flag : STD_LOGIC;
      variable v_c_flag : STD_LOGIC;
  
      variable v_bus_size_check : POSITIVE;
      variable v_error : BOOLEAN := FALSE;
      
    begin
      file_open(v_fstatus, file_check, "..\..\..\Testbench_Files\ALU\" &
          c_filename_input, READ_MODE);
      assert(v_fstatus /= name_error)
      report("Input file does not exist!")
      severity failure;
  
      file_open(v_fstatus, file_log, "..\..\..\Testbench_Files\ALU\" & 
          c_filename_log, WRITE_MODE);
           
      assert(v_fstatus /= name_error)
      report("Log file could not be created!")
      severity failure;
  
      readline(file_check, v_line_pointer_read);
      read(v_line_pointer_read, v_bus_size_check); 
  
      assert(v_bus_size_check = g_bus_size)
      report("Wrong bus size! Failure in line 1.")
      severity failure;
    
    
      report("Started!");
  
      write(v_line_pointer_write, STRING'("Output log for "));
      write(v_line_pointer_write, c_filename_input);
      writeline(file_log, v_line_pointer_write);
      
      
  -- timing for checks:
  --                                    ___                 ___
  --    CLK 4 (ALU)        ____________|   |_______________|   |____________
  --    
  --    ALU_NZVC update    ____________|___________________|________________ 
  --    
  --    SIM_CHECKPOINTS    ______|___|___|___________|___|___|___________|__
  --                       three spikes: set output / check output / check NZVC
  --    us                     3   2   2     3  |  3   2   2    3   |  3   2 


      while not endfile(file_check) loop
        readline(file_check, v_line_pointer_read);
    
        read(v_line_pointer_read, v_input_a);
        read(v_line_pointer_read, v_input_b);
        read(v_line_pointer_read, v_select);
        read(v_line_pointer_read, v_output);
        read(v_line_pointer_read, v_n_flag);
        read(v_line_pointer_read, v_z_flag);
        read(v_line_pointer_read, v_v_flag);
        read(v_line_pointer_read, v_c_flag);
    
        wait for 3 us; -- set output
    
        r_ALU_A <= v_input_a;
        r_ALU_B <= v_input_b;
        r_SEL <= v_select;

        wait for 2 us; -- check output
    
        assert(w_alu_out = v_output)
        report ("Failure in line " & integer'image(v_line_count) & " at output.")
        severity error;

        if w_alu_out /= v_output then
          v_error := TRUE; -- error written at end of line
        end if;
    
        -- Log output
        -- The line of the output corresponds with the line of the input file.
        write(v_line_pointer_write, w_alu_out);
        write(v_line_pointer_write, STRING'(" "));
      
        wait for 2 us; -- check NZVC
      
        assert(w_n_flag = v_n_flag)
        report ("Failure in line " & integer'image(v_line_count) & " at N-flag.")
        severity error;

        assert(w_z_flag = v_z_flag)
        report ("Failure in line " & integer'image(v_line_count) & " at Z-flag.")
        severity error;
      
        assert(w_v_flag = v_v_flag)
        report ("Failure in line " & integer'image(v_line_count) & " at V-flag.")
        severity error;
      
        assert(w_c_flag = v_c_flag)
        report ("Failure in line " & integer'image(v_line_count) & " at C-flag.")
        severity error;
      
        -- Log flags
        write(v_line_pointer_write, w_n_flag);
        write(v_line_pointer_write, w_z_flag);
        write(v_line_pointer_write, w_v_flag); 
        write(v_line_pointer_write, w_c_flag);  
    
        -- Log if check of line was OK
        if((v_error = TRUE) OR (w_n_flag /= v_n_flag) OR (w_z_flag /= v_z_flag) OR 
           (w_v_flag /= v_v_flag) OR (w_c_flag /= v_c_flag)) then
          write(v_line_pointer_write, STRING'(" ERROR:"));
        else
          write(v_line_pointer_write, STRING'(" OK"));
        end if;
        
        -- Log which errors occured
        if(v_error = TRUE) then
          write(v_line_pointer_write, STRING'(" OUT"));
        end if;
        if(w_n_flag /= v_n_flag) then
          write(v_line_pointer_write, STRING'(" N"));
        end if;        
        if(w_z_flag /= v_z_flag) then
          write(v_line_pointer_write, STRING'(" Z"));
        end if;
        if(w_v_flag /= v_v_flag) then
          write(v_line_pointer_write, STRING'(" V"));
        end if;        
        if(w_c_flag /= v_c_flag) then
          write(v_line_pointer_write, STRING'(" C"));
        end if;        
              
        
        writeline(file_log, v_line_pointer_write);
  
 
        wait for 3 us; -- rest of time
      
        v_line_count := v_line_count + 1;
        v_error := FALSE;
  
      end loop;
      
      file_close(file_check);  
      file_close(file_log);  
    
      report("Finished! Checked " & integer'image(v_line_count - 2) & " lines.");
    
      stop_the_clock <= TRUE;
      wait;
    end process PROC_stim;


    PROC_clock: process
    begin    
    
      -- 10 MHz clock with 20% duty cycle
      while not stop_the_clock loop
       r_CLK <= '0';
       wait for 6 us;
       r_CLK <= '1';
       wait for 2 us;
       r_CLK <= '0';
       wait for 2 us;
      end loop;  
      wait;
    end process PROC_clock;
    
end testbench;