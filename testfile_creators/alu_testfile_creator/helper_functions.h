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


#ifndef HELPER_FUNCTIONS_H_INCLUDED
#define HELPER_FUNCTIONS_H_INCLUDED

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

// returns 2**exponent
int power2(unsigned int exponent);

// write a number in binary to a file
// no check if write worked
void writeNumber(long number, unsigned int bit_size, FILE* fp);

// prints number in binary to stdOut
void printNumber(long number, unsigned int bit_size);

// write one line to a file
// always in binary: in_a in_b select(4 bit) output NZVC(in total 4 bit)
void writeLine(long in_a, long in_b, int select, long output,
               int n, int z, int v, int c,
               unsigned int bit_size, FILE* fp, int* error);

// print one line to std_out
// in_a (unsigned decimal and binary) - in_b (unsigned decimal and binary)
// -- select (in decimal) -- output (unsigned decimal and binary) - NZVC
void printLine(long in_a, long in_b, int select, long output,
               unsigned int bit_size, int n, int z, int v, int c);

// prints an error message
void printErrorMessage(int error);

#endif // HELPER_FUNCTIONS_H_INCLUDED
