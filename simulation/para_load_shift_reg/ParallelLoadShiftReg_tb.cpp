#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VParallelLoadShiftReg.h"
#include "VParallelLoadShiftReg___024root.h"

// Test bench files
#include "module.h"

extern int step(int timeStep, TESTBENCH<VParallelLoadShiftReg> *tb, VParallelLoadShiftReg___024root *top);
extern void abort(TESTBENCH<VParallelLoadShiftReg> *tb);

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VParallelLoadShiftReg> *tb = new TESTBENCH<VParallelLoadShiftReg>();

    tb->setup();

    tb->show();

    vluint64_t timeStep = 0;

    VParallelLoadShiftReg *vcore = tb->core();
    VParallelLoadShiftReg___024root *top = vcore->rootp;
    top->load = 1; // disable loading
    top->reset = 1;
    top->shift = 1;

    // Allow any initial blocks to execute
    tb->eval();

    for (size_t i = 0; i < 1000; i++)
    {
        // ------------------ 0A --------------------------
        if (timeStep == 10)
        {
            top->load = 1; // disable loading
            top->data_in = 0xA3;
        }

        if (timeStep == 80)
        {
            top->load = 0; // enable loading
        }

        if (timeStep == 100)
        {
            top->load = 1;
            top->shift = 0;
        }

        if (timeStep == 260)
        {
            top->shift = 1;
        }

        // ------------------ 0B --------------------------
        if (timeStep == 330)
        {
            top->load = 1; // disable loading
            top->data_in = 0xB4;
        }

        if (timeStep == 330 + 70)
        {
            top->load = 0; // enable loading
        }

        if (timeStep == 330 + 70 + 20)
        {
            top->load = 1;
            top->shift = 0;
        }

        if (timeStep == 330 + 70 + 20+160)
        {
            top->shift = 1;
        }

        timeStep = step(timeStep, tb, top);
    }

    top->load = 1; // disable loading
    tb->eval();

    for (size_t i = 0; i < 100; i++)
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
