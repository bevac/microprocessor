/*
BSD 3-Clause License

Copyright (c) 2018, Bernhard Vacarescu
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdlib.h>
#include <stdio.h>

#include "alu.h"
#include "defines.h"
#include "helper_functions.h"

#define SET_FLAG 1
#define DELETE_FLAG 0

#define Z_POS 2
#define N_POS 3
#define V_POS 1
#define C_POS 0

int z_check(long in)
{
  if(in == 0)
  {
    return SET_FLAG;
  }
  else
  {
    return DELETE_FLAG;
  }
}

int n_check(long in, unsigned int bit_size)
{
  if((in & (1 << (bit_size - 1))) == 0)
  {
    return DELETE_FLAG;
  }
  else
  {
    return SET_FLAG;
  }
}

int v_check_addition(long in_a, long in_b, long out, unsigned int bit_size)
{
  // Check if signs of both inputs are the same (only possibility for overflow)
  if((in_a & (1 << (bit_size - 1))) == (in_b & (1 << (bit_size - 1))))
  {
    // Check if output has same sign as in_a (== sign of in_b)
    if((in_a & (1 << (bit_size - 1))) != (out & (1 << (bit_size - 1))))
    {
      return SET_FLAG;
    }
    else
    {
      return DELETE_FLAG;
    }
  }

  return DELETE_FLAG;
}

int v_check_rol(long in_a, unsigned int bit_size)
{
  // If MSB and 2nd MSB of in_a are different an overflow occurs (sign change)
  if( ((in_a & (1 << (bit_size - 1))) >> 1) == (in_a & (1 << (bit_size - 2))) )
  {
    return DELETE_FLAG;
  }

  return SET_FLAG;
}

// works for addition and rol
int c_check(long in, unsigned int bit_size)
{
  if((in & (1 << (bit_size))) != 0)
  {
    return SET_FLAG;
  }
  else
  {
    return DELETE_FLAG;
  }
}


int updateBit(long* in, int position, int value)
{
  if(position > 31) // long has minimum size of 32 bit
  {
    printf("Update bit error: Position too big!");
    return UPDATE_ERROR;
  }

  switch(value)
  {
	  case 0:
    {
      *in &= ~(1 << position);
      break;
    }
	  case 1:
    {
      *in |= 1 << position;
      break;
    }
	  default:
    {
      printf("Update bit error: value not 0 or 1!");
      return UPDATE_ERROR;
    }
  }
  return NO_ERROR;
}


void alu(long in_a, long in_b, int select, long* output,
         int* n_out, int* z_out, int* v_out_check, int* c_out_check,
         unsigned int bit_size, int* error_status)
{
  static int n_flag = 0;
  static int z_flag = 0;
  static int v_flag = 0;
  static int c_flag = 0;

  switch(select)
  {
	  case ALU_TRANSFER: // ALUout <- ALU_A
    {
      *output = in_a;
      n_flag = n_check(*output, bit_size);
      z_flag = z_check(*output);
      v_flag = 0;
      break;
    }
	  case ALU_NOT: // ALUout <- NOT(ALU_A)
    {
      // let the values before stay 0 instead of 1
      // power2(bit_size) -> 1 at every needed position
      *output = (~in_a) & (power2(bit_size) - 1);
      n_flag = n_check(*output, bit_size);
      z_flag = z_check(*output);
      v_flag = 0;
      c_flag = 1;
      break;
    }
	  case ALU_ADD: // ALUout <- ALU_A + ALU_B + Carry
    {
      long tmp = in_a + in_b + c_flag;
      c_flag = c_check(tmp, bit_size);
      *output = tmp & (power2(bit_size) - 1);

      n_flag = n_check(*output, bit_size);
      z_flag = z_check(*output);
      v_flag = v_check_addition(in_a, in_b, *output, bit_size);
      break;
    }
    case ALU_AND: // ALUout <- ALU_A AND ALU_B
    {
      *output = in_a & in_b;
      n_flag = n_check(*output, bit_size);
      z_flag = z_check(*output);
      v_flag = 0;
      break;
    }
    case ALU_ROL: // ALUout <- rol(ALU_A)
    {
      // Shift, add Carry, and delete bit that is shifted out after carry check
      long tmp = ((in_a << 1) | (c_flag));
      c_flag = c_check(tmp, bit_size);
      *output = tmp & (power2(bit_size) - 1);
      v_flag = v_check_rol(in_a, bit_size);
      n_flag = n_check(*output, bit_size);
      z_flag = z_check(*output);
      break;
    }
    case ALU_ROR: // ALUout <- ror(ALU_A)
    {
      *output = (in_a >> 1) | (c_flag << (bit_size - 1));
      n_flag = n_check(*output, bit_size);
      z_flag = z_check(*output);
      c_flag = in_a & 1;
      break;
    }
    case ALU_C0: // C <- 0 (ALUout <- only 1s)
    {
      *output = ~0 & (power2(bit_size) - 1);
      c_flag = 0;
      break;
    }
    case ALU_C1: // C <- 1 (ALUout <- only 1s)
    {
      *output = ~0 & (power2(bit_size) - 1);
      c_flag = 1;
      break;
    }
    case ALU_UPDATE_NZVC:
    {
      *output = in_a;
      updateBit(output, N_POS, n_flag); // Did not use the error check
      updateBit(output, Z_POS, z_flag);
      updateBit(output, V_POS, v_flag);
      updateBit(output, C_POS, c_flag);
      break;
    }
    case ALU_UPDATE_NZV:
    {
      *output = in_a;
      updateBit(output, N_POS, n_flag);
      updateBit(output, Z_POS, z_flag);
      updateBit(output, V_POS, v_flag);
      break;
    }
    case ALU_UPDATE_NZC:
    {
      *output = in_a;
      updateBit(output, N_POS, n_flag);
      updateBit(output, Z_POS, z_flag);
      updateBit(output, C_POS, c_flag);
      break;
    }
    case ALU_UPDATE_Z:
    {
      *output = in_a;
      updateBit(output, Z_POS, z_flag);
      break;
    }
    case ALU_UPDATE_C:
    {
      *output = in_a;
      updateBit(output, C_POS, c_flag);
      break;
    }
    case ALU_13:
    {
      *output = ~0 & (power2(bit_size) - 1);
      break;
    }
    case ALU_14:
    {
      *output = ~0 & (power2(bit_size) - 1);
      break;
    }
    case ALU_15:
    {
      *output = ~0 & (power2(bit_size) - 1);
      break;
    }
	  default:
    {
      *error_status = ALU_ERROR;
    }
  }

  *z_out = z_flag;
  *n_out = n_flag;
  *v_out_check = v_flag;
  *c_out_check = c_flag;
}
