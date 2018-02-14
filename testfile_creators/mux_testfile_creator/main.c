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
#include <time.h>
#include <string.h>

#define NO_ERROR 255
#define ERROR 0
#define FILE_OPEN_ERROR 1
#define FILE_WRITE_ERROR 2 // Did only check this after every complete line
#define MEMORY_ALLOCATION_ERROR 3

#define ENABLE 1
#define DISABLE 0

#define MAX_SELECT_LINES 4
#define MAX_BUS_SIZE 16 // int has at least 16 bit, using INT_MAX

#define MAX_ITERATION_NUMBER 10000
#define LINE_SIZE 32 // Max. string length: LINE_SIZE - 1 ('0' byte).
                     // In program max. length of LINE_SIZE - 2 used.
                     // Length of LINE_SIZE - 1 used to check if too long.
#define PRINT_OUTPUT ENABLE  // Enable/Disable if the question appears if the
                             // file output also should be printed to the
                             // console (formatted differently).

int power2(int exponent);
void printNumber(int number, int bit_size, FILE* fp);


// Returns 2**exponent, only for unsigned values!
int power2(int exponent)
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


// Writes one integer number in binary into a text-file.
// No check if write worked.
void printNumber(int number, int bit_size, FILE* fp)
{
  int mask = 1;
  int counter = 0;

  for(counter = 0; counter < bit_size; counter++)
  {
    if((number & (mask << (bit_size - 1 - counter))) == 0)
    {
      fputc('0', fp);
    }
    else
    {
      fputc('1', fp);
    }
  }
}


int main()
{
  int select_size = 0;
  int bus_size = 0;
  int iteration_number = MAX_ITERATION_NUMBER + 1;
  char filename[LINE_SIZE - 1];
  char line[LINE_SIZE];
  int print_output = DISABLE;

  // Get arguments from stdin
  while(select_size == 0 || select_size > MAX_SELECT_LINES)
  {
    printf("Enter number of select lines (1-%d): ", MAX_SELECT_LINES);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%d", &select_size); //sscanf not reads \n left from fgets
    if(line[strlen(line) - 1] != '\n')
    {
      // flush stdin
      // never considers EOF
      while(getchar() != '\n');
    }
  }
  while(bus_size == 0 || bus_size > MAX_BUS_SIZE)
  {
    printf("Enter bus size (1-%d): ", MAX_BUS_SIZE);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%d", &bus_size);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }
  while(iteration_number > MAX_ITERATION_NUMBER || iteration_number < 0)
  {
    printf("Enter random iteration number (0-%d): ", MAX_ITERATION_NUMBER);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%d", &iteration_number);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }
  do
  {
    printf("Enter text-file name (max. 30 characters): ");
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%s", filename);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }while(strlen(filename) > (LINE_SIZE - 2));

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

  int *inputs = malloc((unsigned)power2(select_size) * sizeof(int));
  if(inputs == NULL)
  {
    printf("Memory allocation error");
    fclose(fp);
    free(inputs);
    getchar();
    return MEMORY_ALLOCATION_ERROR;
  }

  printf("Building MUX test file...\n");

  if(print_output == ENABLE)
  {
    printf("\nDisplayed: 'Inputs'  SEL: 'Selected input', 'Output'\n");
  }

  int number_inputs = power2(select_size);
  int number_select = power2(select_size);

  // At beginning of file: select size and bus size as integers
  fprintf(fp, "%d %d\n", select_size, bus_size);

  int counter = 0;
  int sel_counter = 0;
  int inp_counter = 0;

  // Fix tests
  // See README for description
  if((power2(bus_size) - 1) < (power2(select_size) - 1))
  {
    printf("Bus not long enough for fixed check, "
           "performing only random check!\n");
  }
  else
  {
    for(counter = 0; counter < number_inputs; counter++)
    {
      inputs[counter] = counter;
    }

    for(sel_counter = 0; sel_counter < number_select; sel_counter++)
    {
      for(inp_counter = 0; inp_counter < number_inputs; inp_counter++)
      {
        printNumber(inputs[inp_counter], bus_size, fp); // print inputs
        fputc(' ', fp);

        if(print_output == ENABLE)
        {
          printf("%3d ",inputs[inp_counter]);
        }
      }

      printNumber(sel_counter, select_size, fp); // print select line
      fputc(' ', fp);

      printNumber(inputs[sel_counter], bus_size, fp); // print corresponding
      fputc('\n', fp);                                // output

      if(print_output == ENABLE)
      {
        printf("  SEL: %2d, ",sel_counter);
        printf("%3d\n",inputs[sel_counter]);
      }

      if(ferror(fp))
      {
        printf("Error writing file!");
        fclose(fp);
        free(inputs);
        getchar();
        return FILE_WRITE_ERROR;
      }
    }
  }

  // Random checks
  // Different inputs and a random select are chosen.
  // See README for description
  srand((unsigned)time(NULL)); // randomize seed, that every call of the program
                               // result in different output files
  int sel = 0;

  for(counter = 0; counter < iteration_number; counter++)
  {
    for(inp_counter = 0; inp_counter < number_inputs; inp_counter++)
    {                             // gets ranges of 0 to 2^bus_size
      inputs[inp_counter] = rand() % power2(bus_size);

      printNumber(inputs[inp_counter],  bus_size, fp); // write inputs
      fputc(' ', fp);

      if(print_output == ENABLE)
      {
        printf("%3d ", inputs[inp_counter]);
      }
    }

    sel  = rand() % number_select;

    if(print_output == ENABLE)
    {
      printf("  SEL: %2d, ", sel);
      printf("%3d\n", inputs[sel]);
    }

    // signed conversion suppresses warning, but printNumber only performs
    // on the bits so it does not change anything
    printNumber(sel, select_size, fp); // write select line to file

    fputc(' ', fp);

    printNumber(inputs[sel], bus_size, fp); // write corresponding output
    fputc('\n', fp);

    if(ferror(fp))
    {
      printf("Error writing file!");
      fclose(fp);
      free(inputs);
      getchar();
      return FILE_WRITE_ERROR;
    }
  }

  fclose(fp);
  free(inputs);

  if(print_output == ENABLE)
  {
    printf("\n");
  }

  printf("FINISHED!");
  getchar();

  return 0;
}
