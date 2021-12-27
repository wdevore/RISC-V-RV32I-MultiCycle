#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRegister.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

void sample(VRegister *reg, VerilatedVcdC *m_trace)
{
    sim_time++;
    // reg->clk_i ^= 1;
    std::cout << std::dec << "(" << sim_time << ")" << std::endl;
    reg->eval();
    m_trace->dump(sim_time);
}

void sampleAndClock(VRegister *reg, VerilatedVcdC *m_trace)
{
    sim_time++;
    reg->clk_i ^= 1;
    std::cout << std::dec << "(" << sim_time << ")" << std::endl;
    reg->eval();
    m_trace->dump(sim_time);
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog module
    VRegister *reg = new VRegister;

    // Setup signal capture for GTKwave
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    reg->trace(m_trace, 5);
    m_trace->open("/media/RAMDisk/waveform.vcd");

    // Initially low clock level
    reg->clk_i = 0;
    reg->ld_ni = 1; // disable loading

    sample(reg, m_trace);

    // ------------------ 0A --------------------------
    reg->data_i = 0x000000A0; // Setup data
    std::cout << std::hex << "(" << sim_time << ") "
              << "TBcpp: data in = " << reg->data_i << std::endl;
    reg->ld_ni = 0; // enable loading
    reg->clk_i = 1; // Rising edge
    sample(reg, m_trace);

    reg->ld_ni = 1; // disable loading
    sampleAndClock(reg, m_trace);

    std::cout << std::hex << "(" << sim_time << ") "
              << "TBcpp: data out = " << reg->data_o << std::endl;
    if (reg->data_o != 0x000000A0)
    {
        std::cout << "FAILED: expected 000000A0 got " << reg->data_o << std::endl;
    }

    for (int i = 0; i < 4; i++)
    {
        sampleAndClock(reg, m_trace);
    }

    // ------------------ 0B --------------------------
    reg->data_i = 0x000000B0; // Setup data
    reg->ld_ni = 0;           // enable loading
    reg->clk_i = 1;           // Rising edge
    sample(reg, m_trace);

    reg->ld_ni = 1; // disable loading
    sampleAndClock(reg, m_trace);

    // Add some trailing clocks
    for (int i = 0; i < 5; i++)
    {
        sampleAndClock(reg, m_trace);
    }

    std::cout << "(" << sim_time << ") "
              << "TBcpp: finished." << std::endl;

    reg->final(); // simulation done
    m_trace->close();
    delete reg;

    exit(EXIT_SUCCESS);
}
