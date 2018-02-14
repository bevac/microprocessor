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
-- Communication Testbench
----------------------------------------------------------------------------------
-- Checks the correct operation of the Communication (MBR, MAR) using textfiles.
-- The file ending with _MEM_IN.txt contains the contents of the connected RAM
-- at the beginning of the test.
-- The file ending with _INPUT.txt contains the read or write commands that 
-- should be performed.
-- The file ending with _MEM_OUT.txt contains the content of the connected RAM
-- after all operations.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Change parameters for simulation
package comm_sim_parameters is
    constant c_filename_mem_in : STRING := "comm_test_MEM_IN.txt"; 
    constant c_filename_input : STRING := "comm_test_INPUT.txt"; 
    constant c_filename_mem_out : STRING := "comm_test_MEM_OUT.txt"; 
    constant c_filename_log : STRING := "comm_log.txt";
end package comm_sim_parameters;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

library work;
use work.comm_sim_parameters.all;
use work.datatypes.all;
use work.functions.all;


entity Communication_tb is
  Generic (
    g_bit : POSITIVE := 8
  );
end Communication_tb;



architecture testbench of Communication_tb is

    component Communication
      Generic ( 
        g_bit : POSITIVE
      );
      Port ( 
        i_CLK_MAR : in STD_LOGIC; -- CLK3
        i_CLK_MBR : in STD_LOGIC; -- CLK4
        i_CONTROL : in STD_LOGIC_VECTOR (3 downto 0); -- MBR MAR RD WR
        i_DATA_FROM_ALU : in STD_LOGIC_VECTOR (g_bit-1 downto 0);
        i_A_REG : in STD_LOGIC_VECTOR (g_bit-1 downto 0); -- laoded into MAR L
        i_B_REG : in STD_LOGIC_VECTOR (g_bit-1 downto 0); -- laoded into MAR H
        o_DATA_TO_AMUX : out STD_LOGIC_VECTOR (g_bit-1 downto 0);
        o_ADDRESS : out STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
        io_DATA_MEM : inout STD_LOGIC_VECTOR (g_bit-1 downto 0) -- from/to RAM
      );
    end component;

    signal r_CLK_MAR : STD_LOGIC := '0';
    signal r_CLK_MBR : STD_LOGIC := '0';
    signal r_CONTROL : STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal r_DATA_FROM_ALU : STD_LOGIC_VECTOR (g_bit-1 downto 0) 
        := (others => '0');
    signal r_A_REG : STD_LOGIC_VECTOR (g_bit-1 downto 0) := (others => '0');
    signal r_B_REG : STD_LOGIC_VECTOR (g_bit-1 downto 0) := (others => '0');
    signal w_mbr_content : STD_LOGIC_VECTOR (g_bit-1 downto 0);
    signal w_address : STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
    signal rw_DATA_MEM : STD_LOGIC_VECTOR (g_bit-1 downto 0) := (others => 'Z');
    
    signal r_RAM : t_RAM (0 to 2**(2*g_bit)-1) := 
        initRam("..\..\..\Testbench_Files\Communication\" & 
        c_filename_mem_in, 2**(2*g_bit)-1);

    file file_input : TEXT; 
    file file_mem_out : TEXT;
    
    signal stop_the_clock: BOOLEAN;
    signal init_finished : BOOLEAN;
    
    constant c_clock_period : TIME := 100 ns; -- 10 MHz
    constant c_secondary_clocks_peak : TIME := c_clock_period/5;

begin

    uut: Communication
      generic map ( 
        g_bit => g_bit
      )
      port map ( 
        i_CLK_MAR => r_CLK_MAR,
        i_CLK_MBR => r_CLK_MBR,
        i_CONTROL => r_CONTROL,
        i_DATA_FROM_ALU => r_DATA_FROM_ALU,
        i_A_REG => r_A_REG,
        i_B_REG => r_B_REG,
        o_DATA_TO_AMUX => w_mbr_content,
        o_ADDRESS => w_address,
        io_DATA_MEM => rw_DATA_MEM
      );
                         

    PROC_stim: process
      variable v_line_pointer_read : LINE;
      variable v_line_pointer_write : LINE;
      variable v_fstatus : FILE_OPEN_STATUS;     
      
      variable v_control : STD_LOGIC_VECTOR (3 downto 0);
      variable v_alu_out : STD_LOGIC_VECTOR (g_bit-1 downto 0);
      variable v_address : STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
      variable v_address_check : STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
      variable v_address_int : NATURAL;
      variable v_address_check_int : NATURAL;
      variable v_mbr_content : STD_LOGIC_VECTOR (g_bit-1 downto 0);
      
      variable v_memory_block : STD_LOGIC_VECTOR (g_bit-1 downto 0);
      
      variable hread_ok : BOOLEAN := TRUE;

      variable v_line_count : NATURAL := 1;
 
    begin

      file_open(v_fstatus, file_input, "..\..\..\Testbench_Files\Communication\"
          & c_filename_input, READ_MODE);  
          
      assert(v_fstatus /= name_error)
      report("Input file " & c_filename_input &  " does not exist!")
      severity failure;
      
      file_open(v_fstatus, file_mem_out, "..\..\..\Testbench_Files\Communication\"
          & c_filename_mem_out, READ_MODE);  
          
      assert(v_fstatus /= name_error)
      report("Input file " & c_filename_mem_out &  " does not exist!")
      severity failure;
      
    
      report("Started!");
    
      while not endfile(file_input) loop
        readline(file_input, v_line_pointer_read);
        read(v_line_pointer_read, v_control);
        hread(v_line_pointer_read, v_alu_out);
        read(v_line_pointer_read, v_address_int);
        read(v_line_pointer_read, v_address_check_int);
        hread(v_line_pointer_read, v_mbr_content);
        
        v_address := 
            STD_LOGIC_VECTOR(to_unsigned(v_address_int, 2*g_bit));
        v_address_check := 
            STD_LOGIC_VECTOR(to_unsigned(v_address_check_int, 2*g_bit));
        
        r_CONTROL <= v_control;
        
        -- before CLK3: correct output signal of reg B and A
        wait for 1.5*c_secondary_clocks_peak;
        
        r_A_REG <= v_address(g_bit-1 downto 0);
        r_B_REG <= v_address(2*g_bit-1 downto g_bit);
        
        -- before CLK4:correct signal of ALU out
        -- also check if address correct
        wait for c_secondary_clocks_peak;
        r_DATA_FROM_ALU <= v_alu_out;
        
        assert(w_address = v_address_check)
        report("Adress error at line " & integer'image(v_line_count))
        severity failure;
        
        -- after CLK4: check if MBR correct
        wait for c_secondary_clocks_peak;
        
        assert(w_mbr_content = v_mbr_content)
        report("Wrong MBR content at line " & integer'image(v_line_count))
        severity failure;
        
        wait for 1.5*c_secondary_clocks_peak;
        
        v_line_count := v_line_count + 1;
    
      end loop;
      
      -- checks if all writes were correct (only at end)
      -- (no check if more write at same location)
      for j in 0 to 65535 loop
        readline(file_mem_out, v_line_pointer_read);
        hread(v_line_pointer_read, v_memory_block);
        
        assert(v_memory_block = r_RAM(j))
        report("Wrong contnet at RAM location " & integer'image(j))
        severity failure;
      end loop;
    
      file_close(file_input);  
      file_close(file_mem_out);    
      
      report("Finished! Checked " & integer'image(v_line_count - 1) & " lines.");
      
      stop_the_clock <= TRUE;
      wait;
    end process PROC_stim;
    
    -- imitates an external asynchronous RAM (not clocked)
    PROC_memory: process (r_CONTROL, r_RAM, rw_DATA_MEM, init_finished)
    begin   
      if r_CONTROL(1) = '1' then -- RD
        rw_DATA_MEM <=  r_RAM(to_integer(unsigned((w_address))));
      elsif r_CONTROL(0) = '1' then -- WR
        r_RAM(to_integer(unsigned((w_address)))) <= rw_DATA_MEM;
        rw_DATA_MEM <= (others => 'Z');
      else
        rw_DATA_MEM <= (others => 'Z');
      end if;
    end process PROC_memory;
    
    
    PROC_clock: process
    begin      
        r_CLK_MAR <= '0';
        r_CLK_MBR <= '0';
        
      while not stop_the_clock loop
        wait for 2*c_secondary_clocks_peak;
        r_CLK_MAR <= '1';
        wait for c_secondary_clocks_peak;
        r_CLK_MAR <= '0';
        r_CLK_MBR <= '1';
        wait for c_secondary_clocks_peak;
        r_CLK_MBR <= '0';
        wait for c_secondary_clocks_peak;
      end loop;  
      wait;      
    end process PROC_clock;

end testbench;