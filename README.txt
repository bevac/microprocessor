+------------------------------------------------------------------------------+
|//////////////////////////////////////////////////////////////////////////////|
|//////////////////////+--------------------------------+//////////////////////|
|//////////////////////|           8-bit CISC           |//////////////////////|
|//////////////////////|         MICROPROCESSOR         |//////////////////////|
|//////////////////////|          ARCHITECTURE          |//////////////////////|
|//////////////////////|       described in VHDL        |//////////////////////|
|//////////////////////|                                |//////////////////////|
|//////////////////////|  (c) Bernhard Vacarescu, 2018  |//////////////////////|
|//////////////////////+--------------------------------+//////////////////////|
|//////////////////////////////////////////////////////////////////////////////|
+------------------------------------------------------------------------------+


This project includes a description of a microprocessor architecture in VHDL
that can be programmed on an FPGA. In the following some details of the 
provided project (and the contents of the folders) are described.

The file "Microprocessor_Thesis.pdf" contains the description of the 
implemented architecture. There can be found more detailed explanations about 
the contents of the project that are not included in this file.


+------------------------------------------------------------------------------+
|/////////////////////////////     vhdl_files     /////////////////////////////|
+------------------------------------------------------------------------------+

The folder contains the VHDL modules of the processor project. The module 
"Processor_Controller.vhd" is the top module when implementing the processor 
including RAM (containing the program the processor should execute) and 
further hardware peripherals to test the functionality of the design
in hardware. 

The module "Processor.vhd" contains the microprocessor description which can 
be used for just simulating the processor.

Also the testbench files for most of the (sub-) modules are included.

Some VHDL files use relative paths to use the content of text files. When 
building the project this paths have to be set up correctly (or the paths in 
the files have to be adapted). Further some files need to have a proper name. 


+------------------------------------------------------------------------------+
|//////////////////////////////     ROM_File     //////////////////////////////|
+------------------------------------------------------------------------------+

The folder contains the file that is needed for initializing the microprogram 
memory at simulation and synthesis. It consists of 4096 lines (40 bit each).


+------------------------------------------------------------------------------+
|/////////////////////////////     microcode     //////////////////////////////|
+------------------------------------------------------------------------------+

The folder ontains an excel file file with the complete microcode but including 
more detailed description of the macro programs. The file includes a VBA script 
that can be used to create a file like the one in the "ROM_File" folder.


+------------------------------------------------------------------------------+
|//////////////////////////////     RAM_File     //////////////////////////////|
+------------------------------------------------------------------------------+

Already contains one file that describes a possible content of the RAM when
implementing the "Processor_Controller" module on an FPGA. It was used to
test the functionality of the processor in hardware. The file contains one line
per memory address (65536). In every line the corresponding content is included
in hexadecimal format. After the hexadecimal content comments can be included
in the same line as they have no effect when the file is read in. 

The current configuration of the "Processor_Controller" only uses 12-bit
addresses as this guarantees a faster synthesis. But the stack pointer is still
initialized to 0xFFFF.

Description of the included program:
At program start (and after a hardware reset) the hexadecimal value 34 is 
written to the memory location 257. The both hardware interrupt routines
access the same memory location and increase respectively decrease its content
by one.

How a RAM file has to be set up:
The addresses 0-15 are reserved for interrupt vectors (the total number of
used interrupts can be changed). The memory contents look like this:

Addr.   content
  0       37        JMP-instruction (RESET vector)
  1     HI(RES)     HI-byte of jump address
  2     LO(RES)     LO-byte of jump address
  3       --        does not matter
  4       37        JMP-instruction (SWI vector)
  5     HI(SWI)     HI-byte of jump address
  6     LO(SWI)     LO-byte of jump address 
  7       --        does not matter
  8       37        JMP-instruction (INT1 vector)
  9     HI(INT1)    HI-byte of jump address
 10     LO(INT1)    LO-byte of jump address 
 11       --        does not matter
 12       37        JMP-instruction (INT2 vector)
 13     HI(INT2)    HI-byte of jump address 
 14     LO(INT2)    LO-byte of jump address 
 15       --        does not matter

The combination  of HI(RES) and LO(RES) is the starting address of the main
program. It is also the entrance point if the REST button is pressed.
(As it can be seen from this addressing scheme the architecture is using 
a Big-Endian format.)
The three other addresses jump to a corresponding routine when an software
interrupt occurs (SWI) or an external hardware interrupt is triggered
(INT1 and INT2).

If an interrupt is not used the jump instruction (37) should be replaced by
the instruction 3B (RTI: return from interrupt). 

By default the hardware interrupts are deactivated and have to be activated
by the program.


+------------------------------------------------------------------------------+
|///////////////////     processor_test_program_examples    ///////////////////|
+------------------------------------------------------------------------------+

Contains two example programs that (among others) were used to test the 
functionality of the processor by simulation. They show how the files look
that are used to test the "Processor" module.

To perform a simulation of the "Processor" module the following files are
needed:

- "NAME_MEM_IN.txt" (obligatory): Describes the content of the RAM before
  starting the simulation (like a RAM_File for synthesis).
- "NAME_parameters.txt" (obligatory): Contains parameters to configure the
  simulation.
- "NAME_MEM_OUT.txt" (optional): Contains a (manually) created content of 
  the RAM it should have after the execution of the simulation (used as 
  reference to check if the simulation created the same results).
  
"NAME" can be replaced but has to be the same for every file. In the 
testbench this "NAME" has to be adapted by the constant "c_pre_filename".

"NAME_parameters.txt"-File:
- First it has to contain a bool value (TRUE/FALSE) which specifies if a 
  memory output file "NAME_MEM_OUT.txt" to compare the memory content at the 
  end of the simulation is provided (TRUE if the file should be used).
- A second bool variable specifies the simulation type.
  TRUE: Further two integers have to specified. The first one specifies at 
      which address the processor should stop simulation (when this address 
      is accessed by the processor). The second integer specifies, how often 
      this address has to be accessed before the simulation stops. If the 
      address is never reached the simulation has to be stopped manually.
   FALSE: Starting in the next line an interrupt routine can be used as an 
      input to the processor module. Via the commands "RSET", "INT1" and 
      "INT2" the corresponding hardware interrupt line can be selected 
      followed by a value (0/1) the line should have.
      In addition a "WAIT" command followed by a time duration can be used
      to pause the signal input changes.
      The simulation is stopped after a complete execution of the interrupt
      routine.
      
Caution: Not every possible wrong input is checked. A wrong input can cause 
    unwanted behaviour.
    
A simulation creates the following files:
- "NAME_log.txt": Logs all values of read operations and write operations the
  processor performs including a roughly time stamp of the simulation time
  in microseconds. A log happens when after an operation the RD or WR signal 
  changes back to 0.
- "NAME_mem_log.txt": Contains the content of the memory after a finished 
  simulation (in hexadecimal and decimal). If a comparison with a memory
  output file was performed also the reference values are part of the log 
  file. Every line is completed with "OK" or "ERROR" to indicate if the content
  at this memory location matches with the reference file.
  
For synthesis the buttons of the interrupt lines are debounced (using a 
counter). To reduce simulation time for the simulation the bit size of the
counter to debounce the input lines is reduced.


+------------------------------------------------------------------------------+
|////////////////////////     testbench_generators     ////////////////////////|
+------------------------------------------------------------------------------+

Contains the C-programs that are used to create input files for the simulation
of some modules of the processor.


+------------------------------------------------------------------------------+
|///////////////////////     waveform_configuration     ///////////////////////|
+------------------------------------------------------------------------------+

Contains a waveform configuration file that can be used by the VIVADO Simulator
when simulation the "Prosessor" module. The colours help to see at which
operation cycle of the processor a signal can change.

