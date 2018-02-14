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


#ifndef DEFINES_H_INCLUDED
#define DEFINES_H_INCLUDED


#define NO_ERROR 0
#define ALU_ERROR 1
#define FILE_OPEN_ERROR 2
#define FILE_WRITE_ERROR 3 // Did only check this after every complete line
#define MEMORY_ALLOCATION_ERROR 4
#define UPDATE_ERROR 5

#define ENABLE 1
#define DISABLE 0

//ALU operations
#define ALU_TRANSFER     0
#define ALU_NOT          1
#define ALU_ADD          2
#define ALU_AND          3
#define ALU_ROL          4
#define ALU_ROR          5
#define ALU_C0           6
#define ALU_C1           7
#define ALU_UPDATE_NZVC  8
#define ALU_UPDATE_NZV   9
#define ALU_UPDATE_NZC  10
#define ALU_UPDATE_Z    11
#define ALU_UPDATE_C    12
#define ALU_13          13
#define ALU_14          14
#define ALU_15          15
#define NO_ALU          16


#endif // DEFINES_H_INCLUDED
