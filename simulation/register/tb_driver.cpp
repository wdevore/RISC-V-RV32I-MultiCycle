#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRegister_tb.h"

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    std::cout << "TBcpp: constructing TOP module." << std::endl;

    // initialize Verilog module
    VRegister_tb *reg_tb = new VRegister_tb;

    std::cout << "TBcpp: configuring VCD environment." << std::endl;
    // Setup signal capture for GTKwave
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    reg_tb->trace(m_trace, 5);
    std::cout << "TBcpp: opening waveform.vcd." << std::endl;
    m_trace->open("/media/RAMDisk/waveform.vcd");

    while (!Verilated::gotFinish())
    {
        // cycle the clock
        reg_tb->Clock_TB ^= 1;
        reg_tb->eval();
    }

    std::cout << "TBcpp: finished." << std::endl;

    reg_tb->final(); // simulation done

    m_trace->close();

    delete reg_tb;

    exit(EXIT_SUCCESS);
}
