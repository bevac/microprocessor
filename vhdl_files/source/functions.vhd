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
-- FUNCTIONS
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

library work;
use work.datatypes.all;

package functions is
    -- functions to initialize a memory 
    impure function initRom (RomFileName : in string) return t_ROM;
    -- Ending: last address of the RAM
    impure function initRam (RamFileName : in string; Ending : in positive) return t_RAM;
end;

package body functions is
    impure function initRom (RomFileName : in string) return t_ROM is
      FILE f_rom_file : TEXT open READ_MODE is RomFileName;
      variable v_line_pointer_read : LINE;
      variable v_temp_mem : t_ROM;
    begin
      for i in t_ROM'range loop
        readline(f_rom_file, v_line_pointer_read);
        read(v_line_pointer_read, v_temp_mem(i));
      end loop;
    
      file_close(f_rom_file); 
      return v_temp_mem;
    
    end function;
    
    
    impure function initRam (RamFileName : in string; Ending : in positive) return t_RAM is
      FILE f_ram_file : TEXT open READ_MODE is RamFileName;
      variable v_line_pointer_read : LINE;
      variable v_temp_mem : t_RAM (0 to Ending) := (others => "00000000");
    begin
      for i in 0 to Ending loop
        readline(f_ram_file, v_line_pointer_read);
        hread(v_line_pointer_read, v_temp_mem(i));
      end loop;

      file_close(f_ram_file); 
      return v_temp_mem;
    
    end function;
    
end package body;