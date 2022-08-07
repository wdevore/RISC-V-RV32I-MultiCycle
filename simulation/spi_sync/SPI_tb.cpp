#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <cstdint>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VTop.h"
// #include "VTop_SPIMaster.h" // not really needed
// Needed for the exposed public fields via "*verilator public*"
// and Top module
// #include "VTop___024unit.h"
#include "VTop__Syms.h"

// Test bench files
#include "module.h"

// ------------------------------------------------------------
// Misc
// ------------------------------------------------------------
int step(int timeStep, TESTBENCH<VTop> *tb, VTop *top)
{
    tb->eval();
    tb->dump(timeStep);

    timeStep++;

    if (timeStep % 10 == 0)
        top->pllClk_i ^= 1;

    return timeStep;
}

int assertReset(int timeStep, int duration, TESTBENCH<VTop> *tb, VTop *top)
{
    top->Rst_i_n = 0;
    while (timeStep < duration)
    {
        timeStep = step(timeStep, tb, top);
    }
    top->Rst_i_n = 1;

    return timeStep;
}

int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VTop> *tb = new TESTBENCH<VTop>();

    tb->setup();

    VTop *top = tb->core();
    // Not really needed unless you want to mess with sub-modules
    // VTop_Top *topTop = top->Top;
    // VTop_SPIMaster *spiMaster = topTop->master;

    vluint64_t timeStep = 0;
    int duration = 0;
    int p_ready = 1;

    top->Rst_i_n = 1;
    top->pllClk_i = 0;
    int p_r_Clk = top->pllClk_i;
    top->send_i_n = 1;

    // Allow any initial blocks to execute
    tb->eval();
    timeStep = step(timeStep, tb, top);

    // ---------------------------------------------
    // Perform reset
    // ---------------------------------------------
    duration = 500 + timeStep;
    timeStep = assertReset(timeStep, duration, tb, top);

    // ---------------------------------------------
    // Master sends a byte 0xC5 = 8'b1100_0101
    // Slave sends a byte 0xE4 = 8'b1110_0100
    // ---------------------------------------------
    top->byte_to_slave = 0xC5;
    top->byte_to_master = 0xE4;

    std::cout << "timeStep: " << timeStep << std::endl;

    // Just for visuals, delay 100 PLL clocks before we lower the send signal.
    duration = 100 + timeStep;
    while (timeStep < duration)
    {
        timeStep = step(timeStep, tb, top);
    }

    // VL_PRINTF("send_i_n: %d\n", top->send_i_n);
    // VL_PRINTF("p_ready: %d, %d\n", p_ready, top->ready);

    // Set signal low
    top->send_i_n = 0;
    // and wait for response
    while (!(p_ready == 1 && top->ready == 0))
    {
        p_ready = top->ready;
        timeStep = step(timeStep, tb, top);
    }
    top->send_i_n = 1;
    // VL_PRINTF("send_i_n: %d\n", top->send_i_n);

    // std::cout << "WB timeStep: " << timeStep << std::endl;

    // Wait for the Master to become ready
    while (!(p_ready == 0 && top->ready == 1))
    {
        p_ready = top->ready;
        timeStep = step(timeStep, tb, top);
    }
    // std::cout << "WA timeStep: " << timeStep << std::endl;

    top->byte_to_slave = 0xA2;

    // Set signal low
    top->send_i_n = 0;
    // and wait for response
    while (!(p_ready == 1 && top->ready == 0))
    {
        p_ready = top->ready;
        timeStep = step(timeStep, tb, top);
    }
    top->send_i_n = 1;

    // Wait for the Master to become ready
    while (!(p_ready == 0 && top->ready == 1))
    {
        p_ready = top->ready;
        timeStep = step(timeStep, tb, top);
    }

    // Add a filler 
    duration = 500 + timeStep;
    while (timeStep < duration)
    {
        timeStep = step(timeStep, tb, top);
    }


    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finish TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}
