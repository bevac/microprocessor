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
#include <string.h>
#include <time.h>

#include "alu.h"
#include "defines.h"
#include "helper_functions.h"

#define MAX_BUS_SIZE 16
#define MAX_ITERATION_NUMBER 1000000 // 1 million
// Max. string length: LINE_SIZE - 1 ('0' byte!).
// In program max. length of LINE_SIZE - 2 used.
// Length of LINE_SIZE - 1 used to check if too long.
#define LINE_SIZE 32
// Enable/Disable if the question appears, if the file output also should be
// printed to the console (formatted differently).
#define PRINT_OUTPUT ENABLE


// numbers of combinations in the testing sets
#define NUM_STANDARD_SET 4
#define NUM_ADDITION_SET 5
#define NUM_AND_SET 3
#define NUM_ROL_SET 2
#define NUM_ROR_SET 3

#define NUM_PRETEST_START_SET 3
#define NUM_PRETEST_ROL_SET 1
#define NUM_NZVC_CHECK_SET 23


// Performs one ALU-operation for specific inputs and select line
// Also writes into file and if enabled prints to console
void singleTest
    (long in_a, long in_b, int select, unsigned int bit_size, int* error_status,
     int print_output, FILE* fp)
{
  long output;
  int n;
  int z;
  int v;
  int c;

  alu(in_a, in_b, select, &output, &n, &z, &v, &c, bit_size, error_status);
  if(*error_status != NO_ERROR)
  {
    return;
  }

  writeLine(in_a, in_b, select, output, n, z, v, c, bit_size, fp, error_status);
  if(*error_status != NO_ERROR)
  {
    return;
  }

  if(print_output == ENABLE)
  {
    printLine(in_a, in_b, select, output, bit_size, n, z, v, c);
  }
}


// Perform multiple tests. The inputs and select line are transfered using an
// array (repeating pattern: in_a, in_b, select)
void performTests
    (long* operation_array3, int operation_number, unsigned int bit_size,
     int* error_status, int print_output, FILE* fp)
{
  int counter = 0;
  for(counter = 0; counter < operation_number; counter++)
  {
    singleTest(operation_array3[3 * counter], operation_array3[3 * counter + 1],
               (int)operation_array3[3 * counter + 2], bit_size, error_status,
               print_output, fp);

    if(*error_status != NO_ERROR)
    {
      return;
    }
  }
}

// performs one defined test for one explicit operation
// it gets an array of inputs to perform this test for a specific select
void performFixedTest
    (long* inputs, int operation_number, int select, unsigned int bit_size,
     int* error_status, int print_output, FILE* fp, long MIX, long MAX)
{
  long test_array[3*8] =
      {
        MIX,  4, ALU_ROL,
        0,    0, 0,
        0,    4, ALU_UPDATE_NZVC,
        MAX,  4, ALU_UPDATE_NZVC,
        MAX,  4, ALU_NOT,
        0,    0,    0,
        0,    4, ALU_UPDATE_NZVC,
        MAX,  4, ALU_UPDATE_NZVC
      };

  test_array[5] = (int)select;
  test_array[17] = (int)select;

  int counter = 0;
  for(counter = 0; counter < operation_number; counter++)
  {
    test_array[3] = inputs[2 * counter];
    test_array[4] = inputs[2 * counter + 1];
    test_array[15] = inputs[2 * counter];
    test_array[16] = inputs[2 * counter + 1];

    performTests(test_array, 8, bit_size, error_status, print_output, fp);
    if(*error_status != NO_ERROR)
    {
      return;
    }

    if(print_output == ENABLE)
    {
      printf("     -----     \n");
    }
  }
}



/*
  Written very general. Using long int for the inputs and outputs. Long int
  should have at least 32 bit wide. So it can be used for buses up to 31 bit as
  the 32nd bit is used at the carry calculation.
*/
int main()
{
  int error_status = NO_ERROR;

  unsigned int bit_size = 0;
  long iteration_number = MAX_ITERATION_NUMBER + 1;
  char filename[LINE_SIZE - 1];
  char line[LINE_SIZE];

  int print_output = DISABLE;

  while(bit_size < 4 || bit_size > MAX_BUS_SIZE)
  {
    printf("Enter bus size (4-%d): ", MAX_BUS_SIZE);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%u", &bit_size);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }
  while(iteration_number > MAX_ITERATION_NUMBER || iteration_number < 0)
  {
    printf("Enter random iteration number (0-%d): ", MAX_ITERATION_NUMBER);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%ld", &iteration_number);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }
  do
  {
    printf("Enter text-file name (max. 30 characters): ");
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%s",filename);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }while( (strlen(filename) > (LINE_SIZE - 2)) || (strlen(filename) == 0) );

  if(PRINT_OUTPUT == ENABLE)
  {
    while(1)
    {
      printf("Should output be printed to console? (Y/N): ");
      fgets(line, sizeof(line), stdin); //fgets also inserts newline!
      if((strlen(line) == 2) && (line[0] == 'Y'))
      {
        print_output = ENABLE;
        break;
      }
      else if((strlen(line) == 2) && (line[0] == 'N'))
      {
        break;
      }
      else
      {
        if(line[strlen(line) - 1] != '\n')
        {
          while(getchar() != '\n');
        }
      }
    }
  }

  FILE* fp;
  fp = fopen(filename, "w");
  if(fp == NULL)
  {
    printf("Could not open file!");
    getchar();
    return FILE_OPEN_ERROR;
  }

  // Create defined inputs for fixed testing routine
  long MAX = ~0 & (power2(bit_size) - 1); // only 1 for complete bit_size
  long ZERO = 0;
  long ONE = 1;
  long FOUR = 4;

  long MAX_1 = ~0 & (power2(bit_size) - 1);
  updateBit(&MAX_1, 0, 0); //did not use the error check

  long FIRST = 0 | (1 << (bit_size - 1)); // bits before MSB of bits_size stay 0

  long MIX = 0;
  unsigned int i = 0;
  for(i = 2; i <= bit_size; i += 2) // bits before MSB of bits_size stay 0
  {
    MIX |= (1 << (bit_size - i));
  }



  // Creation of all test-sets
  // Alway in_a and in_b one after another
  long standard_test_set[NUM_STANDARD_SET * 2] =
      { ZERO, FOUR,
        MAX, FOUR,
        ONE, FOUR,
        FIRST, FOUR
      };
  long addition_test_set[NUM_ADDITION_SET * 2] =
      { ZERO, ZERO,
        MAX, MAX,
        ZERO, MAX,
        ONE, FOUR,
        MAX_1, MAX_1
      };
  long and_test_set[NUM_AND_SET * 2] =
      { MAX, FOUR,
        ZERO, MAX,
        MAX, MAX_1
      };
  long rol_test_set[NUM_ROL_SET * 2] =
      { FIRST, FOUR,
        FOUR, MAX
      };
  long ror_test_set[NUM_ROR_SET * 2] =
      { ONE, FOUR,
        FOUR, MAX,
        FIRST, FOUR
      };


  // This pretest sets include also a select after in_a and in_b
  // indicated using the 3 at the end
  long pretest_start_set3[NUM_PRETEST_START_SET * 3] =
      {
        MAX,  FOUR, ALU_NOT,
        MIX,  FOUR, ALU_ROL,
        MAX,  FOUR, ALU_NOT
      };

  long pretest_rol_set3[NUM_PRETEST_ROL_SET * 3] =
      {
        MIX,  FOUR, ALU_ROL
      };


  long NZVC_check_set3[NUM_NZVC_CHECK_SET * 3] =
      {
        ZERO,  MAX,  ALU_UPDATE_NZVC,
        MAX,   ZERO, ALU_UPDATE_NZVC,
        ZERO,  MAX,  ALU_UPDATE_NZVC,

        ZERO,  MAX,  ALU_UPDATE_NZV,
        MAX,   ZERO, ALU_UPDATE_NZV,
        ZERO,  MAX,  ALU_UPDATE_NZV,

        ZERO,  MAX,  ALU_UPDATE_NZVC,
        MAX,   ZERO, ALU_UPDATE_NZVC,

        ZERO,  MAX,  ALU_UPDATE_NZC,
        MAX,   ZERO, ALU_UPDATE_NZC,
        ZERO,  MAX,  ALU_UPDATE_NZC,

        ZERO,  MAX,  ALU_UPDATE_NZVC,
        MAX,   ZERO, ALU_UPDATE_NZVC,

        ZERO,  MAX,  ALU_UPDATE_Z,
        MAX,   ZERO, ALU_UPDATE_Z,
        ZERO,  MAX,  ALU_UPDATE_Z,

        ZERO,  MAX,  ALU_UPDATE_NZVC,
        MAX,   ZERO, ALU_UPDATE_NZVC,

        ZERO,  MAX,  ALU_UPDATE_C,
        MAX,   ZERO, ALU_UPDATE_C,
        ZERO,  MAX,  ALU_UPDATE_C,

        ZERO,  MAX,  ALU_UPDATE_NZVC,
        MAX,   ZERO, ALU_UPDATE_NZVC
      };


  if(print_output == ENABLE)
  {
    printf("\n Decimal representations of values are always unsigned!\n");
    printf("'IN_A' - 'IN_B' -- 'SELECT' -- "
           "'OUTPUT' - 'NZVC'\n\n");
  }


  // At beginning of file: bit size as integer
  fprintf(fp, "%d\n", bit_size);
  if(ferror(fp))
  {
    printErrorMessage(FILE_WRITE_ERROR);
    fclose(fp);
    return FILE_WRITE_ERROR;
  }


  printf("Performing pretests...\n");

  performTests(pretest_start_set3, NUM_PRETEST_START_SET, bit_size,
      &error_status, print_output, fp);
  performTests(NZVC_check_set3, NUM_NZVC_CHECK_SET, bit_size,
      &error_status, print_output, fp);
  performTests(pretest_rol_set3, NUM_PRETEST_ROL_SET, bit_size,
      &error_status, print_output, fp);
  performTests(NZVC_check_set3, NUM_NZVC_CHECK_SET, bit_size,
      &error_status, print_output, fp);

  //error check only after all pretests performed
  if(error_status != NO_ERROR)
  {
    printErrorMessage(error_status);
    fclose(fp);
    return error_status;
  }


  printf("Performing fix tests...\n");


  if(print_output == ENABLE)
  {
    printf("ALU TRANSFER:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_TRANSFER, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU NEGATION:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_NOT, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU ADDITION:\n");
  }
  performFixedTest(addition_test_set, NUM_ADDITION_SET, ALU_ADD, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU AND:\n");
  }
  performFixedTest(and_test_set, NUM_AND_SET, ALU_AND, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU ROL:\n");
  }
  performFixedTest(rol_test_set, NUM_ROL_SET, ALU_ROL, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU ROR:\n");
  }
  performFixedTest(ror_test_set, NUM_ROR_SET, ALU_ROR, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU C<-0:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_C0, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU C<-1:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_C1, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU 13:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_13, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU 14:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_14, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  if(print_output == ENABLE)
  {
    printf("ALU 15:\n");
  }
  performFixedTest(standard_test_set, NUM_STANDARD_SET, ALU_15, bit_size,
      &error_status, print_output, fp, MIX, MAX);

  //error check only after all fixed tests performed
  if(error_status != NO_ERROR)
  {
    printErrorMessage(error_status);
    fclose(fp);
    return error_status;
  }




  // Perform random tests
  printf("Performing random tests...\n");
  srand((unsigned)time(NULL));

  long in_a = 0;
  long in_b = 0;
  int select = 0;

  int counter = 0;
  for(counter = 0; counter < iteration_number; counter++)
  {
    // operation
    in_a = rand() % power2(bit_size); // gets ranges of 0 to 2^bus_size-1
    in_b = rand() % power2(bit_size); // gets ranges of 0 to 2^bus_size-1
    select = rand() % 11; // ALU 0 to 10
    if(select > 7)
    {
      select += 5; // brings range 0-7,13-15
    }

    singleTest(in_a, in_b, select, bit_size, &error_status, print_output, fp);
    if(error_status != NO_ERROR)
    {
      printErrorMessage(error_status);
      fclose(fp);
      return error_status;
    }

    // flag update
    in_a = rand() % power2(bit_size); // gets ranges of 0 to 2^bus_size-1
    in_b = rand() % power2(bit_size); // gets ranges of 0 to 2^bus_size-1
    select = rand() % 5 + 8; // ALU 8-12

    singleTest(in_a, in_b, select, bit_size, &error_status, print_output, fp);
    if(error_status != NO_ERROR)
    {
      printErrorMessage(error_status);
      fclose(fp);
      return error_status;
    }
  }

  fclose(fp);
  printf("Finished!\n");

  getchar();

  return 0;
}
