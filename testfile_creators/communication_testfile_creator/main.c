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
#include <inttypes.h>

#define FILE_OPEN_ERROR 1
#define FILE_WRITE_ERROR 2 // Did only check this after every complete line

#define ENABLE 1
#define DISABLE 0

#define MAX_ITERATION_NUMBER 10000
#define LINE_SIZE 20 // Max. string length: LINE_SIZE - 1 ('0' byte).
                     // In program max. length of LINE_SIZE - 2 used.
                     // Length of LINE_SIZE - 1 used to check if too long.
                     // 32-12 because appended parts to files
                     //
#define PRINT_OUTPUT ENABLE  // Enable/Disable if the question appears if the
                             // file output also should be printed to the
                             // console (formatted differently).

#define ADDRESS_RANGE 65536
#define NUM_RANGE 256


int main()
{
  int iteration_number = MAX_ITERATION_NUMBER + 1;
  char pre_filename[LINE_SIZE - 1];
  char filename_mem_in[LINE_SIZE - 1 + 12];
  char filename_input[LINE_SIZE - 1 + 12];
  char filename_mem_out[LINE_SIZE - 1 + 12];
  char line[LINE_SIZE];
  int print_output = DISABLE;

  // Get arguments from stdin
  while(iteration_number > MAX_ITERATION_NUMBER || iteration_number < 0)
  {
    printf("Enter random iteration number (0-%d): ", MAX_ITERATION_NUMBER);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%d",&iteration_number); // sscanf not reads \n left from fgets
    if(line[strlen(line) - 1] != '\n')
    {
      // flush stdin
      // never considers EOF
      while(getchar() != '\n');
    }
  }
  do
  {
    printf("Enter pre-text-file name (max. %d characters) "
           "- no ending needed: ", LINE_SIZE - 2);
    fgets(line, sizeof(line), stdin);
    sscanf(line, "%s", pre_filename);
    if(line[strlen(line) - 1] != '\n')
    {
      while(getchar() != '\n');
    }
  }while(strlen(pre_filename) > (LINE_SIZE - 2));

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

  strcpy(filename_mem_in, pre_filename);
  strcat(filename_mem_in, "_MEM_IN.txt");
  strcpy(filename_input, pre_filename);
  strcat(filename_input, "_INPUT.txt");
  strcpy(filename_mem_out, pre_filename);
  strcat(filename_mem_out, "_MEM_OUT.txt");


  FILE* fp_mem_in;
  fp_mem_in = fopen(filename_mem_in, "w");
  if(fp_mem_in == NULL)
  {
    printf("Could not open file!");
    getchar();
    return FILE_OPEN_ERROR;
  }

  FILE* fp_input;
  fp_input = fopen(filename_input, "w");
  if(fp_input == NULL)
  {
    printf("Could not open file!");
    fclose(fp_mem_in);
    getchar();
    return FILE_OPEN_ERROR;
  }

  FILE* fp_mem_out;
  fp_mem_out = fopen(filename_mem_out, "w");
  if(fp_mem_out == NULL)
  {
    printf("Could not open file!");
    fclose(fp_mem_in);
    fclose(fp_input);
    getchar();
    return FILE_OPEN_ERROR;
  }

  srand((unsigned)time(NULL)); // randomize seed, that every call of the program
                               // result in different output files


  uint8_t memory[ADDRESS_RANGE - 1];

  long counter = 0;
  for(counter = 0; counter < ADDRESS_RANGE; counter++)
  {
    memory[counter] = (uint8_t)(rand() % NUM_RANGE);
  }

  printf("Writing memory input to \"%s\"...\n", filename_mem_in);

  for(counter = 0; counter < ADDRESS_RANGE; counter++)
  {
    fprintf (fp_mem_in, "%02X\n", memory[counter]);
  }

  if(ferror(fp_mem_in))
  {
     printf("Error writing file!");
     fclose(fp_mem_in);
     fclose(fp_input);
     fclose(fp_mem_out);
     getchar();
     return FILE_WRITE_ERROR;
   }



  printf("Writing input to \"%s\"...\n", filename_input);

  if(print_output == ENABLE)
  {
    printf("\n");
  }

  int rd_wr = 0;
  uint8_t alu_out = 0;
  uint8_t mbr_reg = 0;
  uint16_t addr = 0;
  uint16_t mar_reg = 0;

  for(counter = 0; counter < iteration_number; counter++)
  {
    rd_wr = rand() % 3;

    if(rd_wr == 0) // READ OPERATION
    {
      alu_out = (uint8_t)(rand() % NUM_RANGE);
      addr = (uint16_t)(rand() % ADDRESS_RANGE);
      mar_reg = addr;

      fprintf(fp_input, "0110 %02X %5u %5u %02X RD\n", alu_out, addr,
        mar_reg, mbr_reg);

      alu_out = (uint8_t)(rand() % NUM_RANGE);
      addr = (uint16_t)(rand() % ADDRESS_RANGE);
      mbr_reg = memory[mar_reg];

      fprintf(fp_input, "1010 %02X %5u %5u %02X\n", alu_out, addr,
        mar_reg, mbr_reg);

      if(print_output == ENABLE)
      {
        printf("READ  %02X from MEM[%u] to MBR\n", memory[mar_reg], mar_reg);
      }
    }
    else if(rd_wr == 1)// WRITE OPERATION
    {
      alu_out = (uint8_t)(rand() % NUM_RANGE);
      addr = (uint16_t)(rand() % ADDRESS_RANGE);
      mar_reg = addr;

      fprintf(fp_input, "0100 %02X %5u %5u %02X WR\n", alu_out, addr,
        mar_reg, mbr_reg);

      alu_out = (uint8_t)(rand() % NUM_RANGE);
      addr = (uint16_t)(rand() % ADDRESS_RANGE);
      mbr_reg = alu_out;

      fprintf(fp_input, "1001 %02X %5u %5u %02X\n", alu_out, addr,
        mar_reg, mbr_reg);

      alu_out = (uint8_t)(rand() % NUM_RANGE);
      addr = (uint16_t)(rand() % ADDRESS_RANGE);
      memory[mar_reg] = mbr_reg;

      fprintf(fp_input, "0001 %02X %5u %5u %02X\n", alu_out, addr,
        mar_reg, mbr_reg);

      if(print_output == ENABLE)
      {
        printf("WRITE %02X from MBR to MEM[%u]\n", mbr_reg, mar_reg);
      }
    }
    else // no_operation
    {
      alu_out = (uint8_t)(rand() % NUM_RANGE);
      addr = (uint16_t)(rand() % ADDRESS_RANGE);

      fprintf(fp_input, "0000 %02X %5u %5u %02X NOP\n", alu_out, addr,
        mar_reg, mbr_reg);

      if(print_output == ENABLE)
      {
        printf("NOP\n");
      }
    }

    if(ferror(fp_input))
    {
      printf("Error writing file!");
      fclose(fp_mem_in);
      fclose(fp_input);
      fclose(fp_mem_out);
      getchar();
      return FILE_WRITE_ERROR;
    }
  }

  if(print_output == ENABLE)
  {
    printf("\n");
  }


  printf("Writing memory output to \"%s\"...\n", filename_mem_out);

  for(counter = 0; counter < ADDRESS_RANGE; counter++)
  {
    fprintf (fp_mem_out, "%02X\n", memory[counter]);
  }

  if(ferror(fp_mem_out))
  {
    printf("Error writing file!");
    fclose(fp_mem_in);
    fclose(fp_input);
    fclose(fp_mem_out);
    getchar();
    return FILE_WRITE_ERROR;
  }


  fclose(fp_mem_in);
  fclose(fp_input);
  fclose(fp_mem_out);

  printf("FINISHED!");
  getchar();

  return 0;
}
