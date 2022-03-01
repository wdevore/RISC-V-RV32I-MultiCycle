#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VMux4.h"
#include "VMux4___024root.h"

// Test bench files
#include "module.h"

extern unsigned long int wordToByteAddr(unsigned long int wordaddr);
extern int step(int timeStep, TESTBENCH<VMux4> *tb, VMux4___024root *top);
extern void abort(TESTBENCH<VMux4> *tb);

// This file is similar to a Verilog test bench file except it's C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VMux4> *tb = new TESTBENCH<VMux4>();

    tb->setup();

    tb->show();

    vluint64_t timeStep = 0;

    VMux4 *vcore = tb->core();
    VMux4___024root *top = vcore->rootp;

    // Allow any initial blocks to execute
    tb->eval();

    top->select_i = 0b00;
    top->data0_i = 0x000000A0; // Setup data
    top->data1_i = 0x000000B0;
    top->data2_i = 0x000000C0;
    top->data3_i = 0x000000D0;

    for (size_t i = 0; i < 50; i++)
    {
        // ------------------ 0A --------------------------
        if (timeStep == 10)
        {
            top->select_i = 0b00;
        }

        if (timeStep == 20)
        {
            top->select_i = 0b01;
        }

        // ------------------ 0B --------------------------
        if (timeStep == 30)
        {
            top->select_i = 0b10;
        }

        if (timeStep == 40)
        {
            top->select_i = 0b11;
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
