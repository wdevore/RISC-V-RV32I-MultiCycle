#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRegister.h"
#include "VRegister___024root.h"

// Test bench files
#include "module.h"

extern int step(int timeStep, TESTBENCH<VRegister> *tb, VRegister___024root *top);
extern void abort(TESTBENCH<VRegister> *tb);

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VRegister> *tb = new TESTBENCH<VRegister>();

    tb->setup();

    tb->show();

    vluint64_t timeStep = 0;

    VRegister *vcore = tb->core();
    VRegister___024root *top = vcore->rootp;

    // Allow any initial blocks to execute
    top->ld_i = 1;
    tb->eval();

    for (size_t i = 0; i < 500; i++)
    {
        // ------------------ 0A --------------------------
        if (timeStep == 10)
        {
            top->ld_i = 1; // disable loading
            top->data_i = 0x000000A0;
        }

        if (timeStep == 120)
        {
            top->ld_i = 0; // enable loading
        }

        // ------------------ 0B --------------------------
        if (timeStep == 230)
        {
            top->ld_i = 1; // disable loading
            top->data_i = 0x000000B0;
        }

        if (timeStep == 320)
        {
            top->ld_i = 0; // enable loading
        }

        timeStep = step(timeStep, tb, top);
    }

    for (size_t i = 0; i < 40; i++)
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
