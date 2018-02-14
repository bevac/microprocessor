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
-- Processor Testbench
----------------------------------------------------------------------------------
-- Reads in a RAM content file that includes a program that should be executed.
-- An extra file provides the simulation parameters:
--    - bool (TRUE/FALSE) if at the end the completely memory should be checked
--      with a provided memory output reference file
--    - bool, if the value is TRUE the simulation will be stopped if the processor
--      reaches a certain address, otherwise it finishes after performing the
--      complete interrupt process (generates some interrupt inputs).
--    - integer, that defines at which address the simulation should stop (only
--      needed if previous bool is TRUE)
--    - integer, that defines how often the certain address has to appear until
--      the simulation stops (even only needed if previous bool is TRUE)
-- If an interrupt routine should be performed the parameter file then provides
-- a list of interrupts that should be performed:
--    - RSET, INT1 or INT2 indicating that the value of this certain interrupt
--      should be set, followed by a bit (0/1) indicating which value.
--    - WAIT followed by a time the interrupt process should be paused.
-- The counter size of the debouncing circuit is set to 4 bit that the inputs
-- on the interrupt lines only have to stay on the same level for about 2.2 us
-- that they are recognized (including synchronization).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Change parameter for simulation
package processor_sim_parameters is
    constant c_pre_filename : STRING := "program_7";
end package processor_sim_parameters;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

library work;
use work.processor_sim_parameters.all;
use work.datatypes.all;
use work.functions.all;


entity Processor_tb is
    Generic( 
      g_bit : POSITIVE := 8;
      g_interrupt_line_size : POSITIVE := 2
    );
end Processor_tb;



architecture testbench of Processor_tb is

    component Processor
      Generic( 
        g_bit : POSITIVE := 8;
        g_debounce_counter_bit_size : POSITIVE := 4
      ); 
      Port ( 
        i_CLK : in STD_LOGIC;
        i_RESET_PIN : in STD_LOGIC; 
        i_INTERRUPT: in STD_LOGIC_VECTOR (1 to g_interrupt_line_size);
        o_ADDRESS : out STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
        o_RD : out STD_LOGIC;
        o_WR : out STD_LOGIC;
        o_CLK_MEMORY : out STD_LOGIC;
        o_CLK_MAIN : out STD_LOGIC;
        io_DATA : inout STD_LOGIC_VECTOR (g_bit-1 downto 0) 
      );
    end component;
    
    -- filenames (using constant pre_filename and extending it)
    constant c_filename_mem_in : STRING := c_pre_filename & "_MEM_IN.txt"; 
    constant c_filename_parameters : STRING := c_pre_filename & "_parameters.txt";
    constant c_filename_mem_out : STRING := c_pre_filename & "_MEM_OUT.txt"; 
    constant c_filename_log : STRING := c_pre_filename & "_log.txt";
    constant c_filename_mem_log : STRING := c_pre_filename & "_mem_log.txt";

    file file_mem_in : TEXT; 
    file file_mem_out : TEXT;
    file file_parameters : TEXT;
    file file_log : TEXT; -- log read and write operations
    file file_mem_log : TEXT; -- log memory content
           
    signal r_RAM : t_RAM (0 to 2**(2*g_bit)-1) := 
        initRam("..\..\..\Testbench_Files\Programs\" & 
        c_filename_mem_in, 2**(2*g_bit)-1);
 
    signal r_CLK : STD_LOGIC := '0';

    signal w_address : STD_LOGIC_VECTOR (15 downto 0);
    signal w_rd : STD_LOGIC;
    signal w_wr : STD_LOGIC;
    signal rw_DATA_MEM : STD_LOGIC_VECTOR (7 downto 0) := (others => 'Z');
    
    signal r_RESET : STD_LOGIC := '0';
    signal r_INTERRUPT : STD_LOGIC_VECTOR (1 to 2) := "00";
    alias r_INT1 : STD_LOGIC is r_INTERRUPT(1);
    alias r_INT2 : STD_LOGIC is r_INTERRUPT(2);
    
    -- indicate which finish condition is active
    signal finished_address_condition : BOOLEAN;
    signal finished_interrupts_condition : BOOLEAN;
    -- set that finish condition is reached (if active)
    signal finished_address : BOOLEAN;
    signal finished_interrupts : BOOLEAN;
    
    signal w_end_address : POSITIVE;
    signal w_end_address_count : POSITIVE;
    
    constant c_clock_period : TIME := 10 ns; -- 100 MHz input

begin

    uut: Processor
      port map ( 
        i_CLK => r_CLK,
        i_RESET_PIN => r_RESET,
        i_INTERRUPT => r_INTERRUPT,
        o_ADDRESS => w_address,
        o_RD => w_rd,
        o_WR => w_wr,
        io_DATA => rw_DATA_MEM,
        o_CLK_MEMORY => open, -- simulating asynchronous RAM (not clocked)
        o_CLK_MAIN => open    -- not needed in this simulation
      );
                         

    PROC_stim: process
      variable v_line_pointer_read : LINE;
      variable v_line_pointer_write : LINE;
      variable v_fstatus : FILE_OPEN_STATUS;     
      
      variable v_memory_block : STD_LOGIC_VECTOR (7 downto 0);
      
      variable v_check_memory : BOOLEAN;
      variable v_finish_address : BOOLEAN;
      variable v_end_address : POSITIVE := 100000;
      variable v_end_address_count : POSITIVE := 1;
      
      variable v_end_memory_correct : BOOLEAN := TRUE;
 
    begin
    
      file_open(v_fstatus, file_parameters, "..\..\..\Testbench_Files\Programs\" &
          c_filename_parameters, READ_MODE);  
      
      assert(v_fstatus /= name_error)
      report("Input file " & c_filename_parameters &  " does not exist!")
      severity failure;
      
      readline(file_parameters, v_line_pointer_read);
      read(v_line_pointer_read, v_check_memory);
      read(v_line_pointer_read, v_finish_address);
      
      finished_address_condition <= v_finish_address;
      finished_interrupts_condition <= NOT(v_finish_address);
           
      if v_finish_address = TRUE then
        read(v_line_pointer_read, v_end_address);
        read(v_line_pointer_read, v_end_address_count);
        
        w_end_address <= v_end_address;
        w_end_address_count <= v_end_address_count;
      end if;   
      
      if v_check_memory = TRUE then
        report("Memory will be checked in the end.");
      end if;
      
      if v_finish_address = FALSE then
        report("Interrupt routine will be performed.");
      else
        report("Finish at appearance " & integer'image(v_end_address_count) & 
            " of address " & integer'image(v_end_address) & ".");
      end if;      
      
      file_close(file_parameters); 
      
      if v_check_memory = TRUE then 
        file_open(v_fstatus, file_mem_out, "..\..\..\Testbench_Files\Programs\" &
            c_filename_mem_out, READ_MODE);  
          
        assert(v_fstatus /= name_error)
        report("Input file " & c_filename_mem_out &  " does not exist!")
        severity failure;
      
      end if;

      file_open(v_fstatus, file_mem_log, "..\..\..\Testbench_Files\Programs\" &
          c_filename_mem_log, WRITE_MODE); 
            
      assert(v_fstatus /= name_error)
      report("Memory log file could not be created!")
      severity failure;      
      
      
      file_open(v_fstatus, file_log, "..\..\..\Testbench_Files\Programs\" &
          c_filename_log, WRITE_MODE); 
          
      assert(v_fstatus /= name_error)
      report("Log file could not be created!")
      severity failure;
    
    
      report("Started!");
      
      write(v_line_pointer_write, STRING'("Output log for "));
      write(v_line_pointer_write, c_filename_MEM_IN);
      writeline(file_log, v_line_pointer_write);
      
      -- log read and write operations
      while TRUE loop
        wait until falling_edge(w_rd) OR falling_edge(w_wr) OR 
            (finished_interrupts = TRUE) OR (finished_address = TRUE);
        
        if (finished_interrupts = TRUE) OR (finished_address = TRUE) then
          if finished_address = TRUE then
            write(v_line_pointer_write, STRING'("Finished: Appearance "));
            write(v_line_pointer_write, v_end_address_count);   
            write(v_line_pointer_write, STRING'(" of address "));       
            write(v_line_pointer_write, v_end_address);
            write(v_line_pointer_write, STRING'(" reached."));         
          else -- finished_interrupts = TRUE
            write(v_line_pointer_write, 
                STRING'("Finished: interrupt routine performed completely."));        
          end if;
          writeline(file_log, v_line_pointer_write);
          
          exit; -- exit while loop
        elsif falling_edge(w_rd) then
          write(v_line_pointer_write, STRING'("RD "));
          hwrite(v_line_pointer_write, r_RAM(to_integer(UNSIGNED(w_address))));
          write(v_line_pointer_write, STRING'(" from "));
          write(v_line_pointer_write, to_integer(UNSIGNED(w_address)), right, 5);
          write(v_line_pointer_write, STRING'(" at "));
          write(v_line_pointer_write, integer'image((now/TIME'val(1))/10**6));
          write(v_line_pointer_write, STRING'(" us"));
          writeline(file_log, v_line_pointer_write); 
        elsif falling_edge(w_wr) then
          write(v_line_pointer_write, STRING'("WR "));
          hwrite(v_line_pointer_write, r_RAM(to_integer(UNSIGNED(w_address))));
          write(v_line_pointer_write, STRING'("  to  "));
          write(v_line_pointer_write, to_integer(UNSIGNED(w_address)), right, 5);
          write(v_line_pointer_write, STRING'(" at "));
          write(v_line_pointer_write, integer'image((now/TIME'val(1))/10**6));
          write(v_line_pointer_write, STRING'(" us"));
          writeline(file_log, v_line_pointer_write);      
        end if;
      end loop;
  
      -- checks if all writes were correct 
      -- (only at end, no check if more write at same location were correct)
      if v_check_memory = TRUE then
        for j in 0 to 65535 loop
          readline(file_mem_out, v_line_pointer_read);
          hread(v_line_pointer_read, v_memory_block);
        
          assert(v_memory_block = r_RAM(j))
          report("Wrong content at RAM location " & integer'image(j))
          severity error;
          
          -- memory value
          hwrite(v_line_pointer_write, r_RAM(j));
          write(v_line_pointer_write, to_integer(UNSIGNED(r_RAM(j))), right, 4);
          
          -- reference
          hwrite(v_line_pointer_write, v_memory_block, right, 5);
          write(v_line_pointer_write, to_integer(UNSIGNED(v_memory_block)), right, 7);
          
          if v_memory_block = r_RAM(j) then
            write(v_line_pointer_write, STRING'("   OK"));
          else
            write(v_line_pointer_write, STRING'("   ERROR"));
            v_end_memory_correct := FALSE;
          end if;

          writeline(file_mem_log, v_line_pointer_write);        
        end loop;
        
        if v_end_memory_correct = TRUE then
          report("Memory correct!");
        else
          report("Memory errors!");
        end if;
      else

        for j in 0 to 65535 loop 
          hwrite(v_line_pointer_write, r_RAM(j));
          write(v_line_pointer_write, to_integer(UNSIGNED(r_RAM(j))), right, 4);

          writeline(file_mem_log, v_line_pointer_write);        
        end loop;      
    
      end if;
      
      file_close(file_mem_out);
      file_close(file_log);  
      
      -- because of clock generator process only possible way for automatic stop
      assert FALSE
      report "Simulation finished!"
      severity failure; 
      
    end process PROC_stim;
    
    
    PROC_stop_execution_address: process (w_address)
      variable v_appearance_count : NATURAL := 0;
    begin
      if to_integer(UNSIGNED(w_address)) = w_end_address then
        v_appearance_count := v_appearance_count + 1; 
      end if;   
      if finished_address_condition = TRUE then
        if v_appearance_count = w_end_address_count then
          finished_address <= TRUE; 
        end if;
      end if;
    end process PROC_stop_execution_address;
    
    -- read input file for interrupt generation 
    PROC_execute_int: process
    
      variable v_line_pointer_read : LINE;
      variable v_fstatus : FILE_OPEN_STATUS;  
      -- to make it simple all input strings must have length 4
      variable v_input_string : STRING (1 to 4);
      variable v_input_value : STD_LOGIC;  
      variable v_input_time : TIME; 
      
    begin   
      -- finished_interrupts_condition has to be set before if condition checked, 
      -- therefore waiting 1 ps
      wait for 1 ps; 
      if finished_interrupts_condition = TRUE then
        -- reopen parameter file 
        file_open(v_fstatus, file_parameters, 
            "..\..\..\Testbench_Files\Programs\" & c_filename_parameters, READ_MODE);    
        
        -- read first line (already used -> parameters)
        readline(file_parameters, v_line_pointer_read);
        
        while not endfile(file_parameters) loop
          
          readline(file_parameters, v_line_pointer_read);
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
        
        file_close(file_parameters);
        
        finished_interrupts <= TRUE;
      else
        wait;
      end if;
    end process PROC_execute_int;
    
    
    -- imitates an external asynchronous RAM (not clocked)
    PROC_memory: process (w_rd, w_wr, r_RAM, rw_DATA_MEM, w_address)
    begin   
        if w_rd = '1' then -- RD
          rw_DATA_MEM <=  r_RAM(to_integer(unsigned((w_address))));
        elsif w_wr = '1' then -- WR
          r_RAM(to_integer(unsigned((w_address)))) <= rw_DATA_MEM;
          rw_DATA_MEM <= (others => 'Z');
        else
          rw_DATA_MEM <= (others => 'Z');
        end if;
    end process PROC_memory;
    
    
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