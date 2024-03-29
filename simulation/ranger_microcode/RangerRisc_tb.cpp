#include <stdio.h>
#include <iostream>
#include <iomanip>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRangerRisc.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VRangerRisc___024unit.h"
#include "VRangerRisc__Syms.h"
#include "VRangerRisc_Memory.h"

// Test bench files
#include "module.h"

bool assertionFailure = false;

// Examples of field access
// cmU->ALU_Ops::SraOp

// ------------------------------------------------------------
// Misc
// ------------------------------------------------------------
extern unsigned long int wordToByteAddr(unsigned long int wordaddr);
extern int step(int timeStep, TESTBENCH<VRangerRisc> *tb, VRangerRisc___024root *top);
extern void abort(TESTBENCH<VRangerRisc> *tb);

extern int loop(int timeStep, int baseTime, int duration,
                TESTBENCH<VRangerRisc> *tb,
                VRangerRisc___024root *top,
                VRangerRisc_RangerRisc *const irm,
                VRangerRisc___024unit *const unit);

extern int reset_sequence(int timeStep, int baseTime, int duration,
                TESTBENCH<VRangerRisc> *tb,
                VRangerRisc___024root *top,
                VRangerRisc_RangerRisc *const irm,
                VRangerRisc___024unit *const unit);

void dumpMem(VRangerRisc_Memory *bram)
{
    std::cout << "--------Top Mem-------" << std::endl;
    std::cout << std::setfill('0') << std::hex;
    for (size_t i = 0; i < 200; i++)
    {
        vluint32_t data = bram->mem[i];
        std::cout << "Memory[" << std::setw(2) << i << "] = 0x" << std::setw(8) << std::uppercase << data << std::endl;
    }
    // std::cout << "--------Bottom Mem-------" << std::endl;
    // for (size_t i = 1020; i < 1024; i++)
    // {
    //     vluint32_t data = bram->mem[i];
    //     std::cout << "Memory[" << std::setw(2) << i << "] = 0x" << std::setw(8) << std::uppercase << data << std::endl;
    // }
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VRangerRisc> *tb = new TESTBENCH<VRangerRisc>();

    tb->setup();

    tb->show();

    VRangerRisc *cpu = tb->core();

    VRangerRisc___024unit *const unit = cpu->__PVT____024unit;

    // The top module "RangerRisc"
    VRangerRisc___024root *top = cpu->rootp;

    // Provides access to the sub-modules either privately or publicly.
    VRangerRisc_RangerRisc *const risc = top->RangerRisc;

    VRangerRisc_Pmmu *pmmu = risc->pmmu;
    VRangerRisc_Memory *bram = pmmu->bram;

    // Not really useful for the most part.
    // VRangerRisc__Syms *vlSymsp = risc->vlSymsp;

    // To test "zero delay" Reset sequence set timeStep=0 and duration=0
    // timeStep=10, duration=35.
    vluint64_t timeStep = 0;
    // The reset signal can be held for 0 or more Units for the CPU to sync
    // to the first vector reset state.
    int duration = 0;
    
#if(IRQ_ENABLED == 1)
    top->irq_i = 1;
#endif

    // Allow any initial blocks to execute
    tb->eval();
    timeStep++;
    // dumpMem(bram);

    timeStep = reset_sequence(timeStep, timeStep, duration, tb, top, risc, unit);
    if (assertionFailure)
        abort(tb);

    duration = 15000;

    timeStep = loop(timeStep, timeStep, duration, tb, top, risc, unit);
    if (assertionFailure)
        abort(tb);

    // dumpMem(bram);

    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finish TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}
