#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRegisterFile.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

void sample(VRegisterFile *regFile, VerilatedVcdC *m_trace)
{
    sim_time++;
    // std::cout << std::dec << "(" << sim_time << ")" << std::endl;
    regFile->eval();
    m_trace->dump(sim_time);
}

void sampleAndClock(VRegisterFile *reg, VerilatedVcdC *m_trace)
{
    sim_time++;
    reg->clk_i ^= 1;
    // std::cout << std::dec << "(" << sim_time << ")" << std::endl;
    reg->eval();
    m_trace->dump(sim_time);
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog module
    VRegisterFile *regFile = new VRegisterFile;

    // Setup signal capture for GTKwave
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    regFile->trace(m_trace, 5);
    m_trace->open("/media/RAMDisk/waveform.vcd");

    std::cout << "(" << sim_time << ") "
              << "TBcpp: starting." << std::endl;

    // Initially low clock level
    regFile->clk_i = 0;
    regFile->reg_we_ni = 1; // disable writing

    regFile->data_i = 0x000000A0; // Setup data
    regFile->reg_dst_i = 1;       // destination = reg 1
    regFile->reg_srcA_i = 0;      // reg 0 output on A
    regFile->reg_srcB_i = 1;      // reg 1 output on B

    sample(regFile, m_trace);

    // ------------------ read 00 --------------------------
    if (regFile->srcB_o != 0x00000000)
    {
        std::cout << std::dec << "(" << sim_time << ")"
                  << "FAILED: expected 00000000 got " << std::hex << regFile->reg_srcB_i << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sampleAndClock(regFile, m_trace);
    }

    // ------------------ write A0 to Reg 1 --------------------------
    regFile->reg_we_ni = 0; // enable writing
    sampleAndClock(regFile, m_trace);
    sampleAndClock(regFile, m_trace);

    regFile->reg_we_ni = 1; // disable writing
    for (int i = 0; i < 2; i++)
    {
        sampleAndClock(regFile, m_trace);
    }

    if (regFile->srcB_o != 0x000000A0)
    {
        std::cout << std::dec << "Reg B (" << sim_time << ") "
                  << "FAILED: expected 000000A0 got '" << std::hex << regFile->srcB_o << "'" << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sampleAndClock(regFile, m_trace);
    }

    // ------------------ write B0 to Reg 2 --------------------------
    regFile->data_i = 0x000000B0; // Setup data
    regFile->reg_we_ni = 0;       // enable writing
    regFile->reg_dst_i = 2;       // destination = reg 2
    regFile->reg_srcA_i = 2;      // reg 2 output on A
    sampleAndClock(regFile, m_trace);

    regFile->reg_we_ni = 1; // disable writing
    for (int i = 0; i < 2; i++)
    {
        sampleAndClock(regFile, m_trace);
    }

    if (regFile->srcA_o != 0x000000B0)
    {
        std::cout << std::dec << "Reg A (" << sim_time << ") "
                  << "FAILED: expected 000000A0 got '" << std::hex << regFile->srcB_o << "'" << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sampleAndClock(regFile, m_trace);
    }
    std::cout << "(" << sim_time << ") "
              << "TBcpp: finished." << std::endl;

    regFile->final(); // simulation done
    m_trace->close();
    delete regFile;

    exit(EXIT_SUCCESS);
}
