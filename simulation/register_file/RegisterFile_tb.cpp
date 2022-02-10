#include <stdio.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRegisterFile.h"
#include "VRegisterFile___024root.h"
#include "VRegisterFile_RegisterFile.h"

// Test bench files
#include "module.h"

bool assertionFailure = false;

extern unsigned long int wordToByteAddr(unsigned long int wordaddr);
extern int step(int timeStep, TESTBENCH<VRegisterFile> *tb, VRegisterFile___024root *top);
extern void abort(TESTBENCH<VRegisterFile> *tb);

void clearMem(VRegisterFile_RegisterFile *regFile)
{
    for (int i = 0; i < 32; i++)
    {
        regFile->bank[i] = 0;
    }
}

void dumpMem(VRegisterFile_RegisterFile *regFile)
{
    for (int i = 0; i < 32; i++)
    {
        vluint32_t data = regFile->bank[i];
        VL_PRINTF("Reg [%2d] = 0x%08x\n", i, data);
    }
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VRegisterFile> *tb = new TESTBENCH<VRegisterFile>();

    tb->setup();

    tb->show();

    vluint64_t timeStep = 0;

    VRegisterFile *vcore = tb->core();
    VRegisterFile___024root *top = vcore->rootp;
    VRegisterFile_RegisterFile *regFile = top->RegisterFile;

    // Allow any initial blocks to execute
    tb->eval();

    clearMem(regFile);
    tb->eval();
    dumpMem(regFile);

    top->reg_we_i = 1;        // disable writing
    top->data_i = 0x000000A0; // Setup data
    top->reg_dst_i = 1;       // destination = reg 1
    top->reg_srcA_i = 0;      // reg 0 output on A
    top->reg_srcB_i = 1;      // reg 1 output on B

    for (int i = 0; i < 100; i++)
    {
        // ------------------ write 0xA0 to Reg 1 --------------------------
        if (timeStep == 10)
        {
            top->data_i = 0x000000A0;
            top->reg_we_i = 0;
        }

        if (timeStep == 25)
        {
            top->reg_we_i = 1;
        }

        // ------------------ write 0x0B to Reg 2 --------------------------
        if (timeStep == 30)
        {
            top->reg_dst_i = 2;  // destination = reg 2
            top->reg_srcA_i = 2; // reg 2 output on A
            top->reg_we_i = 0;
            top->data_i = 0x000000B0;
        }

        if (timeStep == 45)
        {
            top->reg_we_i = 1;
        }

        // ------------------ Attemp to write 0xC0 to Reg 0 -------------------
        if (timeStep == 50)
        {
            top->reg_dst_i = 0;  // destination = reg 0
            top->reg_srcA_i = 0; // reg 0 output on A
            top->reg_we_i = 0;
            top->data_i = 0x000000C0;
        }

        if (timeStep == 65)
        {
            top->reg_we_i = 1;
        }

        timeStep = step(timeStep, tb, top);
    }

    // Assertion: Reg 0 always returns a Zero
    vluint64_t regV = regFile->bank[0];
    if (regV != 0x00000000)
    {
        std::cout << std::dec << "Reg 0 (" << timeStep << ") "
                  << "Assertion FAILED: expected 0x00000000 got '" << std::hex << regV << "'" << std::endl;
        abort(tb);
    }

    // Check Reg 1
    regV = regFile->bank[1];
    if (regV != 0x000000A0)
    {
        std::cout << std::dec << "Reg 1 (" << timeStep << ") "
                  << "Assertion FAILED: expected 0x000000A0 got '" << std::hex << regV << "'" << std::endl;
        abort(tb);
    }

    // Check Reg 2
    regV = regFile->bank[2];
    if (regV != 0x000000B0)
    {
        std::cout << std::dec << "Reg 1 (" << timeStep << ") "
                  << "Assertion FAILED: expected 0x000000B0 got '" << std::hex << regV << "'" << std::endl;
        abort(tb);
    }

    std::cout << "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" << std::endl;

    dumpMem(regFile);

    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finish TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}
