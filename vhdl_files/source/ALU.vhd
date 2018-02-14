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
-- ALU (Arithmetic Logic Unit)
----------------------------------------------------------------------------------
-- included part(s): 
--    SERIAL ADDER
----------------------------------------------------------------------------------
-- Performs different operations using up to two operands. The operation is
-- selected via a select line. Four clocked registers save flag conditions
-- of the last operation (zero-flag, negative-flag, overflow-flag, carry-flag).
-- The bus size of the ALU is a generic value (but it must be at least 4 as
-- the flag-update instructions of the ALU affect the last four bits).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.ALL; -- includes or_reduce()


entity ALU is
    Generic ( 
      g_bit : positive -- bit size of operands (has to be be at least 4)
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
end ALU;



architecture Mixed of ALU is

    component Serial_Adder is
      Generic ( 
        g_bit: positive 
      );
      Port( 
        i_A, i_B : in STD_LOGIC_VECTOR (g_bit-1 downto 0);
        i_CARRY : in STD_LOGIC;
        o_CARRY, o_V : out STD_LOGIC;
        o_Y : out STD_LOGIC_VECTOR (g_bit-1 downto 0) 
      );
    end component;
  
    signal w_alu_output : STD_LOGIC_VECTOR (g_bit-1 downto 0);

    -- registers that save the flag values
    signal r_Z_FLAG : STD_LOGIC := '0';
    signal r_N_FLAG : STD_LOGIC := '0';
    signal r_C_FLAG : STD_LOGIC := '0';
    signal r_V_FLAG : STD_LOGIC := '0';
 
    -- calculated Z-flag and N-flag from uutput
    signal w_z_calc : STD_LOGIC;
    signal w_n_calc : STD_LOGIC;

    -- new values for flags
    signal w_z_new : STD_LOGIC;
    signal w_n_new : STD_LOGIC;
    signal w_c_new : STD_LOGIC;
    signal w_v_new : STD_LOGIC;
  
    -- adder outputs
    signal w_c_out_adder : STD_LOGIC;
    signal w_v_out_adder : STD_LOGIC;
    signal w_out_adder : STD_LOGIC_VECTOR (g_bit-1 downto 0);
  
begin

    COMP_Adder: Serial_Adder
      generic map ( 
        g_bit => g_bit 
      )
      port map ( 
        i_A => i_ALU_A, 
        i_B => i_ALU_B, 
        i_CARRY => r_C_FLAG,
        o_CARRY => w_c_out_adder, 
        o_V => w_v_out_adder,
        o_Y => w_out_adder 
      );


    -- Updates the status flags
    PROC_clk: process (i_CLK)
    begin
      if(rising_edge(i_CLK)) then
        r_Z_FLAG <= w_z_new;
        r_N_FLAG <= w_n_new;
        r_C_FLAG <= w_c_new;
        r_V_FLAG <= w_v_new;
      end if;
    end process PROC_clk;


    PROC_output: process
      (i_ALU_A, i_ALU_B, i_SEL, w_z_calc, w_n_calc, w_out_adder, w_c_out_adder, 
       w_v_out_adder, r_Z_FLAG, r_N_FLAG, r_C_FLAG, r_V_FLAG)
    begin   
      case i_SEL is   
        when "0000" =>      -- ALUout <= ALU_A
          w_alu_output <= i_ALU_A;  
      
          w_z_new <= w_z_calc;
          w_n_new <= w_n_calc;
          w_c_new <= r_C_FLAG;
          w_v_new <= '0'; 
    
        when "0001" =>      -- ALUout <= NOT(ALU_A)
          w_alu_output <= NOT i_ALU_A;  
      
          w_z_new <= w_z_calc;
          w_n_new <= w_n_calc;
          w_c_new <= '1';
          w_v_new <= '0';       
    
        when "0010" =>      -- ALUout <= ALU_A + ALU_B + Carry
          w_alu_output <= w_out_adder;
      
          w_z_new <= w_z_calc;
          w_n_new <= w_n_calc;
          w_c_new <= w_c_out_adder;
          w_v_new <= w_v_out_adder;
    
        when "0011" =>      -- ALUout <= ALU_A AND ALU_B
          w_alu_output <= i_ALU_A AND i_ALU_B;  
      
          w_z_new <= w_z_calc;
          w_n_new <= w_n_calc;
          w_c_new <= r_C_FLAG;
          w_v_new <= '0'; 
    
        when "0100" =>      -- ALUout <= rol(ALU_A) (rotate left with carry)
          w_alu_output <= i_ALU_A(g_bit-2 downto 0) & r_C_FLAG;
      
          w_z_new <= w_z_calc;
          w_n_new <= w_n_calc;
          w_c_new <= i_ALU_A(g_bit-1);
          w_v_new <= i_ALU_A(g_bit-1) XOR i_ALU_A(g_bit-2);
    
        when "0101" =>      -- ALUout <= ror(ALU_A) (rotate right with carry)
           w_alu_output <= r_C_FLAG & i_ALU_A(g_bit-1 downto 1);
      
          w_z_new <= w_z_calc;
          w_n_new <= w_n_calc;
          w_c_new <= i_ALU_A(0);
          w_v_new <= r_V_FLAG; 
    
        when "0110" =>      -- Carry <= 0 (defined: ALUout <= '1' for all bits)
          w_alu_output <= (others => '1');
      
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= '0';
          w_v_new <= r_V_FLAG; 
    
        when "0111" =>      -- Carry <= 1 (defined: ALUout <= '1' for all bits)
          w_alu_output <= (others => '1');
      
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= '1';
          w_v_new <= r_V_FLAG; 
    
        when "1000" =>      -- ALUout <= (N,Z,V,C) ° ALU_A  
          w_alu_output <= i_ALU_A(g_bit-1 downto 4) & 
                          r_N_FLAG & r_Z_FLAG & r_V_FLAG & r_C_FLAG;
                   
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= r_C_FLAG;
          w_v_new <= r_V_FLAG;                    
    
        when "1001" =>      -- ALUout <= (N,Z,V) ° ALU_A
          w_alu_output <= i_ALU_A(g_bit-1 downto 4) & 
                          r_N_FLAG & r_Z_FLAG & r_V_FLAG & i_ALU_A(0);
                   
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= r_C_FLAG;
          w_v_new <= r_V_FLAG;                    
    
        when "1010" =>      -- ALUout <= (N,Z,C) ° ALU_A
          w_alu_output <= i_ALU_A(g_bit-1 downto 4) & 
                          r_N_FLAG & r_Z_FLAG & i_ALU_A(1)& r_C_FLAG ;
                 
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= r_C_FLAG;
          w_v_new <= r_V_FLAG;                  
    
        when "1011" =>      -- ALUout <= (Z) ° ALU_A
          w_alu_output <= i_ALU_A(g_bit-1 downto 3) & 
                          r_Z_FLAG & i_ALU_A(1 downto 0);
                   
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= r_C_FLAG;
          w_v_new <= r_V_FLAG;                    
    
        when "1100" =>      -- ALUout <= (C) ° ALU_A
          w_alu_output <= i_ALU_A(g_bit-1 downto 1) & r_C_FLAG;
      
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= r_C_FLAG;
          w_v_new <= r_V_FLAG;      
    
        when others =>      -- (defined: ALUout <= '1' for all bits) 
          w_alu_output <= (others => '1');
      
          w_z_new <= r_Z_FLAG;
          w_n_new <= r_N_FLAG;
          w_c_new <= r_C_FLAG;
          w_v_new <= r_V_FLAG;                               
      end case;
    end process PROC_output;   


    -- calculate Z-flag and N-flag from output
    w_z_calc <= NOT(or_reduce(w_alu_output));
    w_n_calc <= w_alu_output(g_bit-1);

    -- outputs
    o_Z_FLAG <= r_Z_FLAG;
    o_N_FLAG <= r_N_FLAG;
    o_V_FLAG <= r_V_FLAG;
    o_C_FLAG <= r_C_FLAG;
    o_ALU_OUT <= w_alu_output;

end Mixed;
