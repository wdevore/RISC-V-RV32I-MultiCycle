#include <stdio.h>
#include <iostream>
#include <iomanip>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VPmmu.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VMemory___024root.h"
#include "VPmmu__Syms.h"

// Test bench files
#include "module.h"

void dumpMem(VPmmu_Memory *bram)
{
    std::cout << std::setfill('0') << std::hex;
    for (size_t i = 0; i < 20; i++)
    {
        vluint32_t data = bram->mem[i];
        std::cout << "Memory[" << std::setw(2) << i << "] = 0x" << std::setw(8) << std::uppercase << data << std::endl;
    }
}

unsigned long int wordToByteAddr(unsigned long int wordaddr)
{
    return wordaddr * 4;
}

int step(int timeStep, TESTBENCH<VPmmu> *tb, VPmmu___024root *top)
{
    tb->eval();
    tb->dump(timeStep);

    timeStep++;

    if (timeStep % 10 == 0)
        top->clk_i ^= 1;

    return timeStep;
}

void abort(TESTBENCH<VPmmu> *tb)
{
    tb->shutdown();

    delete tb;

    exit(EXIT_FAILURE);
}
