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


#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#include "helper_functions.h"
#include "defines.h"

int power2(unsigned int exponent)
{
  if(exponent == 0)
  {
    return 1;
  }
  else
  {
    return 1 << exponent;
  }
}

void writeNumber(long number, unsigned int bit_size, FILE* fp)
{
  long mask = 1;
  unsigned int counter = 0;

  for(counter = 0; counter < bit_size; counter++)
  {
    if((number & (mask << (bit_size - 1 - counter))) == 0)
    {
      fputc('0',fp);
    }
    else
    {
      fputc('1',fp);
    }
  }
}

void printNumber(long number, unsigned int bit_size)
{
  long mask = 1;
  unsigned int counter = 0;

  for(counter = 0; counter < bit_size; counter++)
  {
    if((number & (mask << (bit_size - 1 - counter))) == 0)
    {
      printf("0");
    }
    else
    {
      printf("1");
    }
  }
}


void writeLine(long in_a, long in_b, int select, long output,
               int n, int z, int v, int c,
               unsigned int bit_size, FILE* fp, int* error)
{
  writeNumber(in_a, bit_size, fp);
  fputc(' ', fp);
  writeNumber(in_b, bit_size, fp);
  fputc(' ', fp);
  writeNumber(select, 4, fp);
  fputc(' ', fp);
  writeNumber(output, bit_size, fp);
  fputc(' ', fp);
  writeNumber(n, 1, fp);
  writeNumber(z, 1, fp);
  writeNumber(v, 1, fp);
  writeNumber(c, 1, fp);
  fputc('\n', fp);

  // Only check after complete line
  if(ferror(fp))
  {
    *error = FILE_WRITE_ERROR;
    return;
  }
}


void printLine(long in_a, long in_b, int select, long output,
               unsigned int bit_size, int n, int z, int v, int c)
{
  printf("%3lu ", (unsigned long)in_a);
  printNumber(in_a, bit_size);
  printf(" - %3lu ", (unsigned long)in_b);
  printNumber(in_b, bit_size);
  printf(" -- %2d --", select);
  printf(" %3lu ", (unsigned long)output);
  printNumber(output, bit_size);
  printf(" - %d%d%d%d ", n, z, v, c);
  printf("\n");
}


void printErrorMessage(int error)
{
  switch(error)
  {
    case ALU_ERROR:
    {
      printf("Select number illegal!");
    }
    case FILE_WRITE_ERROR:
    {
      printf("Could not write file!");
    }
    default:
    {
      printf("Unknown error!\n");
    }
  }
}
