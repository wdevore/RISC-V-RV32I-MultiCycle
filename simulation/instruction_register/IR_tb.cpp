#include <stdio.h>
#include <iostream>
#include <iomanip>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VIRModule.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VIRModule___024unit.h"
#include "VIRModule__Syms.h"
#include "VIRModule_Memory.h"
// #include "VIRModule___024root.h"

// Test bench files
#include "module.h"

bool assertionFailure = false;

// Examples of field access
// cmU->ALU_Ops::SraOp

// ------------------------------------------------------------
// Misc
// ------------------------------------------------------------
extern unsigned long int wordToByteAddr(unsigned long int wordaddr);
extern int step(int timeStep, TESTBENCH<VIRModule> *tb, VIRModule___024root *top);
extern void abort(TESTBENCH<VIRModule> *tb);

extern int reset_sequence(int timeStep, int baseTime, int duration,
    TESTBENCH<VIRModule> *tb,
    VIRModule___024root *top,
    VIRModule_IRModule *const irm,
    VIRModule___024unit *const unit);

extern int fetch_sequence(int timeStep, int baseTime, int duration,
    TESTBENCH<VIRModule> *tb,
    VIRModule___024root *top,
    VIRModule_IRModule *const irm,
    VIRModule___024unit *const unit);

void dumpMem(VIRModule_Memory *bram)
{
    std::cout << "--------Top Mem-------" << std::endl;
    std::cout << std::setfill('0') << std::hex;
    for (size_t i = 0; i < 25; i++)
    {
        vluint32_t data = bram->mem[i];
        std::cout << "Memory[" << std::setw(2) << i << "] = 0x" << std::setw(8) << std::uppercase << data << std::endl;
    }
    std::cout << "--------Bottom Mem-------" << std::endl;
    for (size_t i = 1020; i < 1024; i++)
    {
        vluint32_t data = bram->mem[i];
        std::cout << "Memory[" << std::setw(2) << i << "] = 0x" << std::setw(8) << std::uppercase << data << std::endl;
    }
}

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VIRModule> *tb = new TESTBENCH<VIRModule>();

    tb->setup();

    tb->show();

    VIRModule *vir = tb->core();

    // Provides access to the Enums, for example,
    // cmU->MatrixState::Fetch
    VIRModule___024unit *const unit = vir->__PVT____024unit;

    // The top module "IRModule"
    VIRModule___024root *top = vir->rootp;

    // Provides access to the sub-modules either privately or publicly.
    VIRModule_IRModule *const irm = top->IRModule;
    // The sub-modules
    VIRModule_ControlMatrix *cm = irm->matrix;
    VIRModule_Register *ir = irm->ir;

    VIRModule_Pmmu *pmmu = irm->pmmu;
    VIRModule_Memory *bram = pmmu->bram;

    // Not really useful for the most part.
    // VIRModule__Syms *vlSymsp = irm->vlSymsp;

    vluint64_t timeStep = 0;

    int duration = 45;
    int baseTime = 10;

    // Allow any initial blocks to execute
    tb->eval();
    dumpMem(bram);

    timeStep = reset_sequence(timeStep, baseTime, duration, tb, top, irm, unit);
    if (assertionFailure)
        abort(tb);

    duration = 45;
    baseTime = timeStep;

    timeStep = fetch_sequence(timeStep, baseTime, duration, tb, top, irm, unit);
    if (assertionFailure)
        abort(tb);

    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // I-Type: NOP is encoded as ADDI x0, x0, 0
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // funct7 | rs2 | rs1 | funct3 | rd   |  opcode
    // 0000000 00000 00000   000    00000   0010011
    // Nibbles: 0000_0000_0000_0000_0000_0000_0001_0011
    // Hex: 0x00000013
    // top->ir_i = 0x00000013;

    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // R-Type: add x5, x6, x7   =>   x5 = x6 + x7
    // From: Nihongo/Hardware/RISC-V/RISC-V Instruction Formats.pdf
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // funct7 | rs2 | rs1 | funct3 | rd   |  opcode
    // 0000000 00111 00110   000    00101   0110011
    // Nibbles: 0000_0000_0111_0011_0000_0010_1011_0011
    // Hex: 0x007302B3
    // top->ir_i = 0x007302B3;

    std::cout << "Running to duration" << std::endl;
    int testDuration = timeStep + 75;
    while (timeStep < testDuration)
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