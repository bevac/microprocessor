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
-- PROCESSOR (single part)
----------------------------------------------------------------------------------
-- included part(s): 
--    ALU, MBR, MICROSEQUENCER, MUX (MMux and AMux), EVENT CONTROLLER,
--    MMCM UNIT WRAPPER (block design for clock generator)
----------------------------------------------------------------------------------
-- Very general description of the processor architecture. Some parts could be
-- changed using generic values. 
-- Using a data bus the processor can load data from an external memory (RAM) or
-- store data (location determined via address bus and operation via RD and WR 
-- bits).
-- An external reset button can reset the processor using microcode (the RAM
-- does not change to its start up value!).
-- One (or more interrupt lines) are available.
-- The Basys3 board offers a 100 MHz clock. The ClockGenerator module reduces
-- the clock speed to 10 MHz, which is also output of the clock generator and is 
-- then treated as if this would have been the actual input clock ("virtual 
-- input clock"), as also the derived clocks are operating at 10 MHz.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.datatypes.all;
use work.functions.all;

-- g_bit: architecture type (standard: 8-bit architecture)
--    The architecture type also effects the possible accessible 
--    address range of the RAM.
-- g_interrupt_line_size: number of external interrupt lines (e.g. buttons)
--    According to the code there has to be at least 1 interrupt line.
-- g_debounce_counter_bit_size: bit size of counter used for debouncing reset
--    and interrupt buttons.
--    For debouncing of about 10 ms for 10 MHz clock speed a 17 bit-counter
--    is needed.
--
-- Changing one of the other generics would need bigger changes in the
-- architecture! (Size of MPM, microcode, number of internal registers,...)
--
-- g_dec_sel_size: number of decoder select lines (2**g_dec_sel_size internal 
--    registers)
-- g_mmux_bus_size: mmux bus size (address range of MPM)
-- g_mmux_sel_size: number of MMux select lines
-- g_amux_sel_size: number of AMux select lines (input from MBR and A-reg)

entity Processor is
    Generic( 
      g_bit : positive := 8;
      g_interrupt_line_size : positive := 2;
      g_debounce_counter_bit_size : positive := 17; 
      g_dec_sel_size : positive := 5;
      g_mmux_bus_size : positive := 12;
      g_mmux_sel_size : positive := 2;
      g_amux_sel_size : positive := 1
    ); 
    Port ( 
      i_CLK : in STD_LOGIC;
      i_RESET_PIN : in STD_LOGIC; 
      i_INTERRUPT: in STD_LOGIC_VECTOR (1 to g_interrupt_line_size);
      o_ADDRESS : out STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
      o_RD : out STD_LOGIC;
      o_WR : out STD_LOGIC;
      o_CLK_MEMORY : out STD_LOGIC;  -- clock for RAM operations
      o_CLK_MAIN : out STD_LOGIC;  -- "virtual input clock" (reduced speed)
      io_DATA : inout STD_LOGIC_VECTOR (g_bit-1 downto 0)  -- connection to RAM
    );
end Processor;



architecture Mixed of Processor is
    
    -- output of the event controller, can be loaded into EVENT register
    signal w_event_control : STD_LOGIC_VECTOR (g_bit-1 downto 0);
  
    -- derived clock lines via MMCM
    signal w_clks : STD_LOGIC_VECTOR (1 to 5);
    alias w_clk1 : STD_LOGIC is w_clks(1);
    alias w_clk2 : STD_LOGIC is w_clks(2);
    alias w_clk3 : STD_LOGIC is w_clks(3);
    alias w_clk4 : STD_LOGIC is w_clks(4);
    alias w_clk5 : STD_LOGIC is w_clks(5);
    
    -- reduced speed of input clock from board: used as "virtual input clock" 
    signal w_main_clk : STD_LOGIC;
    
    -- type for internal registers
    type t_REG is array (0 to 2**g_dec_sel_size-1) 
        of STD_LOGIC_VECTOR (g_bit-1 downto 0);
  
    -- initialisation of the 32 8-bit registers
    signal r_REGISTERS : t_REG := (
      4 => (others => '1'), -- SPH
      5 => (others => '1'), -- SPL
      6 => (others => '0'), -- PCH
      7 => (others => '0'), -- PCL 
      9 => (4 => '1', others => '0'), -- CC (interrupts disabled)
     15 => (g_bit-1 => '1', others => '0'), -- EVENT (no event status)
     -- CONSTANT REGISTERS (removed as registers at synthesis)
     20 => (g_bit-1 => '1', others => '0'), -- no event status
     21 => STD_LOGIC_VECTOR(to_signed(-5, g_bit)),  -- -5 / 251
     22 => STD_LOGIC_VECTOR(to_signed(-4, g_bit)),  -- -4 / 252
     23 => STD_LOGIC_VECTOR(to_signed(-3, g_bit)),  -- -3 / 253
     24 => STD_LOGIC_VECTOR(to_signed(-2, g_bit)),  -- -2 / 254
     25 => STD_LOGIC_VECTOR(to_signed(-1, g_bit)),  -- -1 / 255
     26 => STD_LOGIC_VECTOR(to_unsigned(16, g_bit)),-- 16
     27 => STD_LOGIC_VECTOR(to_unsigned(8, g_bit)), -- 8
     28 => STD_LOGIC_VECTOR(to_unsigned(4, g_bit)), -- 4
     29 => STD_LOGIC_VECTOR(to_unsigned(2, g_bit)), -- 2
     30 => STD_LOGIC_VECTOR(to_unsigned(1, g_bit)), -- 1
     31 => (others => '0'),                         -- 0
      others => (others => '0')
    );
    
    -- only for signal rom_style can be defined (not for a constant)
    signal r_MPM : t_ROM := initROM("..\..\..\ROM_File\ROM_MEM.txt");
    
    attribute rom_style : string;   
    attribute rom_style of r_MPM : signal is "block";
       
  -------------------------------------------------------------------------------- 
  -- further registers
  --
  
    signal r_A_REG : STD_LOGIC_VECTOR (g_bit-1 downto 0) := (others => '0');
    signal r_B_REG : STD_LOGIC_VECTOR (g_bit-1 downto 0) := (others => '0');

    signal r_MPC : STD_LOGIC_VECTOR (11 downto 0) := "000000000000";
    
    -- initial value: jump to address 0x000 in MPM; processor can only start
    -- if other value is loaded into MIR
    signal r_MIR : STD_LOGIC_VECTOR (39 downto 0) 
        := "0011111100000111111111111111000000000000";
   
    alias r_OP_MIR : STD_LOGIC is r_MIR(39);
    alias r_AMUX_MIR : STD_LOGIC is r_MIR(38);
    alias r_COND_MIR : STD_LOGIC_VECTOR is r_MIR(37 downto 36);
    alias r_ALU_MIR : STD_LOGIC_VECTOR is r_MIR(35 downto 32);
    alias r_COMMUNICATION_MIR : STD_LOGIC_VECTOR is r_MIR(31 downto 28);
    alias r_MBR_MIR : STD_LOGIC is r_MIR(31);
    alias r_MAR_MIR : STD_LOGIC is r_MIR(30);
    alias r_RD_MIR : STD_LOGIC is r_MIR(29);
    alias r_WR_MIR : STD_LOGIC is r_MIR(28);
    alias r_ENC_MIR : STD_LOGIC is r_MIR(27);
    alias r_C_MIR : STD_LOGIC_VECTOR is r_MIR(26 downto 22);
    alias r_B_MIR : STD_LOGIC_VECTOR is r_MIR(21 downto 17);
    alias r_A_MIR : STD_LOGIC_VECTOR is r_MIR(16 downto 12);
    alias r_ADDRESS_MIR : STD_LOGIC_VECTOR is r_MIR(11 downto 0);
    
    
  -------------------------------------------------------------------------------- 
  -- connection lines
  --
  
    signal w_a_bus : STD_LOGIC_VECTOR (g_bit-1 downto 0);
    signal w_b_bus : STD_LOGIC_VECTOR (g_bit-1 downto 0);
       
    signal w_alu_a : STD_LOGIC_VECTOR (g_bit-1 downto 0);
    signal w_alu_z : STD_LOGIC;
    signal w_alu_n : STD_LOGIC;
    signal w_alu_out : STD_LOGIC_VECTOR (g_bit-1 downto 0); 
  
    signal w_mbr_to_amux : STD_LOGIC_VECTOR (g_bit-1 downto 0);
    signal w_j_cond : STD_LOGIC;
    signal w_mmux_sel : STD_LOGIC_VECTOR (1 downto 0);
    signal w_mpc_plus : STD_LOGIC_VECTOR (11 downto 0);
    signal w_instruct : STD_LOGIC_VECTOR (11 downto 0);
    signal w_mmux_to_mpc : STD_LOGIC_VECTOR (11 downto 0);
   
    signal w_amux_in : t_MUX_ARRAY 
        (0 to 2**g_amux_sel_size-1, g_bit-1 downto 0);
    signal w_mmux_in : t_MUX_ARRAY 
        (0 to 2**g_mmux_sel_size-1, g_mmux_bus_size-1 downto 0);
    
    -- constant used for interrupts (definition of no event)
    constant c_no_event : STD_LOGIC_VECTOR (g_bit-1 downto 0) 
        := (g_bit-1 => '1', others => '0');
    
begin

  -------------------------------------------------------------------------------- 
  -- connect components
  --
  
    Communication_inst : entity work.Communication
      generic map ( 
        g_bit => g_bit
      )
      port map (
        i_CLK_MAR => w_clk3,
        i_CLK_MBR => w_clk4,
        i_CONTROL => r_COMMUNICATION_MIR,
        i_DATA_FROM_ALU => w_alu_out,
        i_A_REG => r_A_REG,
        i_B_REG => r_B_REG,
        o_DATA_TO_AMUX => w_mbr_to_amux,
        o_ADDRESS => o_ADDRESS,
        io_DATA_MEM => IO_DATA
      );
             
    Microsequencer_inst: entity work.Microsequencer
      port map ( 
        i_Z => w_alu_z,
        i_N => w_alu_n,
        i_COND => r_COND_MIR,
        o_J => w_j_cond 
      ); 
   
    ALU_inst: entity work.ALU
      generic map( 
        g_bit => g_bit 
      )
      port map ( 
        i_ALU_A => w_alu_a,
        i_ALU_B => r_B_REG,
        i_SEL => r_ALU_MIR,
        i_CLK => w_clk4,
        o_ALU_OUT => w_alu_out,
        o_Z_FLAG => w_alu_z,
        o_N_FLAG => w_alu_n,             
        o_V_FLAG => open, -- ouput only used for simulation
        o_C_FLAG => open  -- ouput only used for simulation
      );

    ClockGenerator: entity work.MMCM_unit_wrapper
      port map ( 
        clk_in1 => i_CLK,
        clk_out1 => w_clk1,
        clk_out2 => w_clk2,
        clk_out3 => w_clk3,
        clk_out4 => w_clk4,
        clk_out5 => w_clk5,
        clk_out6 => w_main_clk,
        reset => '0',  -- reset not used
        locked => open -- ouput only used for simulation
      );
 
    Amux: entity work.MUX
      generic map ( 
        g_bus_size => g_bit,
        g_sel_size => g_amux_sel_size
      )
      port map ( 
        i_SELECT(0) => r_AMUX_MIR,
        i_INPUTS => w_amux_in,
        o_OUTPUT => w_alu_a
      );
                         
    Mmux: entity work.MUX
      generic map ( 
        g_bus_size => g_mmux_bus_size,
        g_sel_size => g_mmux_sel_size
      )
      port map ( 
        i_SELECT => w_mmux_sel,
        i_INPUTS => w_mmux_in,
        o_OUTPUT => w_mmux_to_mpc
      );         
                         
        
    EventController_int: entity work.Event_Controller
      generic map ( 
        g_bit_size_counter => g_debounce_counter_bit_size,
        g_bit_size => g_bit,
        g_int_lines => g_interrupt_line_size 
      )
      port map ( 
        i_RESET => i_RESET_PIN,
        i_CLK => w_main_clk,
        i_INTERRUPT => i_INTERRUPT,
        o_event_control => w_event_control
      );
    
    
  -------------------------------------------------------------------------------- 
  -- processes for connecting the multiplexers correctly  
  --
    
    PROC_amux_connect: process(r_A_REG, w_mbr_to_amux)
    begin
      for i in 0 to g_bit-1 loop
        w_amux_in(0,i) <= r_A_REG(i);
        w_amux_in(1,i) <= w_mbr_to_amux(i);
      end loop;
    end process PROC_amux_connect;
    
    PROC_mmux_connect: process(w_mpc_plus, r_ADDRESS_MIR, w_instruct)
    begin
      for i in 0 to g_mmux_bus_size-1 loop
        w_mmux_in(0,i) <= w_mpc_plus(i);
        w_mmux_in(1,i) <= w_instruct(i);
        w_mmux_in(2,i) <= r_ADDRESS_MIR(i);
        w_mmux_in(3,i) <= w_instruct(i);
      end loop;
    end process PROC_mmux_connect;
    
    w_mmux_sel(0) <= r_OP_MIR;
    w_mmux_sel(1) <= w_j_cond;
                                                                                  
                                                                                  
  -------------------------------------------------------------------------------- 
  -- clocked processes (for communication (MAR and MBR) and ALU external modules) 
  --
  
    -- load MIR
    PROC_CLK1: process (w_clk1)
    begin
      if rising_edge(w_clk1) then
        r_MIR <= r_MPM(to_integer(UNSIGNED(r_MPC)));
      end if;
    end process PROC_CLK1;    
    

    -- load A- and B register
    PROC_CLK2: process (w_clk2)
      begin
        if rising_edge(w_clk2) then
          r_A_REG <= w_a_bus;
          r_B_REG <= w_b_bus;
        end if;
    end process PROC_CLK2;    
    
    
    -- load internal registers
    -- reset- and interrupt-pin (event) also synchronous to clock
    PROC_CLK4: process (w_clk4)
    begin
      if rising_edge(w_clk4) then
        if (r_ENC_MIR = '1') then
           
          -- synthesis translate_off
          -- no write operation to registers with constants allowed
          assert(to_integer(UNSIGNED(r_C_MIR)) < 20)
          report("C-Bus-Error: Unallowed write! (microcode wrong)")
          severity failure;
          
          -- only "no_event"-constant or available hardware interrupt-vector- 
          -- number is allowed to be loaded into the EVENT register
          if to_integer(UNSIGNED(r_C_MIR)) = 15 then
            assert( (w_alu_out = c_no_event) OR 
                ((to_integer(UNSIGNED(w_alu_out)) > 1 ) AND
                 (to_integer(UNSIGNED(w_alu_out)) < (g_interrupt_line_size + 2))))
            report("C-Bus-Error: Unallowed write content for EVENT register!" & 
                "(microcode wrong)")
            severity failure;
          end if;
          -- synthesis translate_on 
          
          
          -- C decoder
          -- As no write to registers 20-31 is allowed, synthesis removes this
          -- registers (constant values)
          if to_integer(UNSIGNED(r_C_MIR)) < 20 then
            r_REGISTERS(to_integer(UNSIGNED(r_C_MIR))) <= w_alu_out;
          end if;
        end if;
        
        -- additional possible load of the EVENT reister, depending on
        -- the content of the EVENT register and the value of w_event_control
        if (w_event_control /= c_no_event) AND 
           ( to_integer(UNSIGNED(w_event_control)) < 
             to_integer(UNSIGNED(r_REGISTERS(15))) ) then
          r_REGISTERS(15) <= w_event_control;
        end if;
              
       end if; 
    end process PROC_CLK4;


    -- load MPC
    PROC_CLK5: process (w_clk5)
    begin
      if rising_edge(w_clk5) then
          r_MPC <= w_mmux_to_mpc;
      end if;
    end process PROC_CLK5;
    
    
  -------------------------------------------------------------------------------- 
  -- further connections
  --

    -- synthesis translate_off
    -- it is not possible to read from IR
    assert ( (to_integer(UNSIGNED(r_A_MIR)) /= 14) AND 
             (to_integer(UNSIGNED(r_B_MIR)) /= 14) )
    report("C-Bus-Error: Unallowed read (IR-reg)! (microcode wrong)")
    severity failure;
    -- synthesis translate_on 
  
    -- A- and B decoder (load A- and B-bus)
    w_a_bus <= r_REGISTERS(to_integer(UNSIGNED(r_A_MIR)));
    w_b_bus <= r_REGISTERS(to_integer(UNSIGNED(r_B_MIR)));  
   
    -- instruction decoder
    w_instruct <= r_REGISTERS(14)(7 downto 0)  & "0000";
    
    w_mpc_plus <= STD_LOGIC_VECTOR(UNSIGNED(r_MPC) + 1);
  
    -- outputs
    o_RD <= r_RD_MIR;
    o_WR <= r_WR_MIR;
    o_CLK_MEMORY <= w_clk1;
    o_CLK_MAIN <= w_main_clk;
    
end Mixed;