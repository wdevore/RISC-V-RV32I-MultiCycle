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

    top->Rst_i_n = 1;
    top->pllClk_i = 0;

    // Allow any initial blocks to execute
    tb->eval();
    timeStep = step(timeStep, tb, top);

    duration = 25 + timeStep;
    while (timeStep < duration)
    {
        timeStep = step(timeStep, tb, top);
    }

    // ---------------------------------------------
    // Perform reset
    // ---------------------------------------------
    duration = 100 + timeStep;
    timeStep = assertReset(timeStep, duration, tb, top);

    std::cout << "timeStep: " << timeStep << std::endl;

    // Run enough clocks for IOModule to send 3 bytes
    duration = 20000 + timeStep;
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
