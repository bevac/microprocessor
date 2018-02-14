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


#ifndef ALU_H_INCLUDED
#define ALU_H_INCLUDED

// main ALU function: changes the output and the flags depending on the
// inputs a and b, the select line and the old flags, which are saved using
// static variables
void alu(long in_a, long in_b, int select, long* output,
          int* n_out, int* z_out, int* v_out_check, int* c_out_check,
          unsigned int bit_size, int* error_status);

// At bit position the value ('0' or '1') is changed of input
int updateBit(long* in, int position, int value);

// Return if the flag has to be set/cleared depending on the inputs
int z_check(long in);
int n_check(long in, unsigned int bit_size);
int v_check_addition(long in_a, long in_b, long out, unsigned int bit_size);
int v_check_rol(long in_a, unsigned int bit_size);
int c_check(long in, unsigned int bit_size);


#endif // ALU_H_INCLUDED
