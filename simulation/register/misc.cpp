// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRegister.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VRegister__Syms.h"

// Test bench files
#include "module.h"

unsigned long int wordToByteAddr(unsigned long int wordaddr)
{
    return wordaddr * 4;
}

int step(int timeStep, TESTBENCH<VRegister> *tb, VRegister___024root *top)
{
    tb->eval();
    tb->dump(timeStep);

    timeStep++;

    if (timeStep % 10 == 0)
        top->clk_i ^= 1;
    return timeStep;
}

void abort(TESTBENCH<VRegister> *tb)
{
    tb->shutdown();

    delete tb;

    exit(EXIT_FAILURE);
}
