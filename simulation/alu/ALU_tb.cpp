#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VALU.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

void sample(VALU *alu, VerilatedVcdC *m_trace)
{
    sim_time++;
    // std::cout << std::dec << "(" << sim_time << ")" << std::endl;
    alu->eval();
    m_trace->dump(sim_time);
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog module
    VALU *alu = new VALU;

    // Setup signal capture for GTKwave
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    alu->trace(m_trace, 5);
    m_trace->open("/media/RAMDisk/waveform.vcd");

    std::cout << "(" << sim_time << ") "
              << "TBcpp: starting." << std::endl;

    std::cout << "(" << sim_time << ") "
              << "TBcpp: finished." << std::endl;

    alu->final(); // simulation done
    m_trace->close();
    delete alu;

    exit(EXIT_SUCCESS);
}
