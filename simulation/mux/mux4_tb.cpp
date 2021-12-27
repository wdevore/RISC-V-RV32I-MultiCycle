#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VMux4.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

void sample(VMux4 *mux, VerilatedVcdC *m_trace)
{
    sim_time++;
    // std::cout << std::dec << "(" << sim_time << ")" << std::endl;
    mux->eval();
    m_trace->dump(sim_time);
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog module
    VMux4 *mux = new VMux4;

    // Setup signal capture for GTKwave
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    mux->trace(m_trace, 5);
    m_trace->open("/media/RAMDisk/waveform.vcd");

    // Initially low clock level
    mux->select_i = 0b00;
    mux->data0_i  = 0x000000A0; // Setup data
    mux->data1_i  = 0x000000B0;
    mux->data2_i  = 0x000000C0;
    mux->data3_i  = 0x000000D0;

    sample(mux, m_trace);

    // ------------------ 0A --------------------------
    if (mux->data_o != 0x000000A0)
    {
        std::cout << "FAILED: expected 000000A0 got " << mux->data_o << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sample(mux, m_trace);
    }

    // ------------------ 0B --------------------------
    mux->select_i = 0b01;
    sample(mux, m_trace);

    if (mux->data_o != 0x000000B0)
    {
        std::cout << "FAILED: expected 000000B0 got " << mux->data_o << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sample(mux, m_trace);
    }

    // ------------------ 0C --------------------------
    mux->select_i = 0b10;
    sample(mux, m_trace);

    if (mux->data_o != 0x000000C0)
    {
        std::cout << "FAILED: expected 000000C0 got " << mux->data_o << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sample(mux, m_trace);
    }

    // ------------------ 0C --------------------------
    mux->select_i = 0b11;
    sample(mux, m_trace);

    if (mux->data_o != 0x000000D0)
    {
        std::cout << "FAILED: expected 000000D0 got " << mux->data_o << std::endl;
    }

    for (int i = 0; i < 2; i++)
    {
        sample(mux, m_trace);
    }

    std::cout << "(" << sim_time << ") "
              << "TBcpp: finished." << std::endl;

    mux->final(); // simulation done
    m_trace->close();
    delete mux;

    exit(EXIT_SUCCESS);
}
