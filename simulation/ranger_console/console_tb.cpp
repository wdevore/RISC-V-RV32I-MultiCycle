#include <stdio.h>
#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "commands.h"
#include "console.h"
#include "property.h"

#define ESC '\x1B'

#include <verilated.h>
#include <verilated_vcd_c.h>

// Files generated by Verilator
#include "VRangerRisc.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VRangerRisc___024unit.h"
#include "VRangerRisc__Syms.h"
#include "VRangerRisc_Memory.h"

// Test bench files
#include "console_module.h"

// Examples of field access
// cmU->ALU_Ops::SraOp

// ------------------------------------------------------------
// Misc
// ------------------------------------------------------------
extern unsigned long int wordToByteAddr(unsigned long int wordaddr);
extern int step(int timeStep, VRangerRisc___024root *top);
extern void abort(TESTBENCH<VRangerRisc> *tb);

extern int reset_sequence(
    int timeStep,
    TESTBENCH<VRangerRisc> *tb,
    VRangerRisc___024root *top);

void dumpMem(VRangerRisc_Memory *bram)
{
    std::cout << "--------Top Mem-------" << std::endl;
    std::cout << std::setfill('0') << std::hex;
    for (size_t i = 0; i < 35; i++)
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
    // --------------------------------------------------
    // initialize Verilog (aka SystemVerilog) module
    // --------------------------------------------------
    Verilated::commandArgs(argc, argv);

    TESTBENCH<VRangerRisc> *tb = new TESTBENCH<VRangerRisc>();

    tb->setup();

    VRangerRisc *cpu = tb->core();

    VRangerRisc___024unit *const unit = cpu->__PVT____024unit;

    // The top module "RangerRisc"
    VRangerRisc___024root *top = cpu->rootp;

    // Provides access to the sub-modules either privately or publicly.
    VRangerRisc_RangerRisc *const risc = top->RangerRisc;
    // The sub-modules
    VRangerRisc_ControlMatrix *cm = risc->matrix;
    VRangerRisc_Register *ir = risc->ir;
    VRangerRisc_Register *pc = risc->pc;

    VRangerRisc_Pmmu *pmmu = risc->pmmu;
    VRangerRisc_Memory *bram = pmmu->bram;

    // Not really useful for the most part.
    // VRangerRisc__Syms *vlSymsp = risc->vlSymsp;

    vluint64_t timeStep_ns = 0;

    // Default to clock low
    top->clk_i = 0;

    // Allow any initial blocks to execute (timeStep 0->1)
    timeStep_ns = tb->eval(timeStep_ns); // each eval() is 1 "time unit" = 1ns
    timeStep_ns++;

    int p_clk_i = top->clk_i;

    Property<vluint8_t> ready_sig{};

    // dumpMem(bram);

    //
    //      |--- cycle ---|
    //       ______        ______        ______        ______
    //      |      |      |      |      |      |      |
    //______|      |______|      |______|      |______|
    //
    //      | half |
    //        cycle

    const int fullCycle = 20; // Units (nanoseconds)
    const int halfCycle = fullCycle / 2;
    int stepSize = 0;
    int stepCnt = 0;

    // Each timescale step can be delayed
    // For example, if the HDL step is 1ns then each
    // 1ns step will occur every 10ms.
    int timeStepDelayms = 10; // Default 10ms = 100Hz
    bool delayEnabled = true;

    bool looping = true;
    bool clockEnabled = true;

    // Disabling the sim means bypassing the call to eval();
    bool simRunning = true;

    // --------------------------------------------------
    // initialize NCurses
    // --------------------------------------------------
    int row = 2;
    Console *con = new Console();
    con->init();

    con->start();

    con->showULIntProperty(row++, 1, "timeStep", timeStep_ns);
    con->showBoolProperty(row++, 1, "Sim running", simRunning);
    con->showIntProperty(row++, 1, "Delay time", timeStepDelayms);
    con->showIntProperty(row++, 1, "Step size", stepSize);
    con->showClockEdge(row++, 1, 2, timeStep_ns);
    con->showIntProperty(row++, 1, "Ready", cm->ready);
    con->showIntProperty(row++, 1, "Reset", top->reset_i);
    con->showIntProperty(row++, 1, "State", cm->state);
    con->showIntProperty(row++, 1, "Vec State", cm->vector_state);

    // Default to holding CPU in reset state
    top->reset_i = 1;

    while (looping)
    {
        Command cmd = con->handleInput();

        switch (cmd)
        {
        case Command::Reset:
            timeStep_ns = 0;
            stepCnt = 0;
            break;
        case Command::Signal:
            // Enable cpu reset pin and wait for reset-complete
            top->reset_i = con->getArg2() == "l" ? 0 : 1;
            con->showIntProperty(8, 1, "Reset", top->reset_i);
            break;
        case Command::NStep:
            stepCnt = 0;
            stepSize = 1;
            con->showIntProperty(5, 1, "Step size", stepSize);
            break;
        case Command::HCStep:
            stepCnt = 0;
            stepSize = halfCycle;
            con->showIntProperty(5, 1, "Step size", stepSize);
            break;
        case Command::FLStep:
            stepCnt = 0;
            stepSize = fullCycle;
            con->showIntProperty(5, 1, "Step size", stepSize);
            break;
        case Command::SetReg:
            con->markForUpdate();
            break;
        case Command::EnableSim:
            simRunning = con->getArg1Bool();
            con->showBoolProperty(3, 1, "Sim running", simRunning);
            break;
        case Command::EnableDelay:
            delayEnabled = con->getArg1Bool();
            break;
        case Command::DelayTime:
            timeStepDelayms = con->getArg1Int();
            con->showIntProperty(3, 1, "Delay time", timeStepDelayms);
            break;
        case Command::Exit:
            looping = false;
            continue;
        default:
            break;
        }

        // ---------------------------------------------------
        // Simulation update
        // ---------------------------------------------------
        if (simRunning)
        {
            if (stepCnt < stepSize)
            {
                // The clock toggles every half-cycle
                if (timeStep_ns % halfCycle == 0)
                    top->clk_i ^= 1;

                timeStep_ns = tb->eval(timeStep_ns); // each eval() is 1 "timescale" = 1ns

                ready_sig.set(top->ready_o, timeStep_ns);

                con->showULIntProperty(2, 1, "timeStep", timeStep_ns);

                row = 6;
                // Clock edges
                if (p_clk_i == 0 && top->clk_i == 1)
                    con->showClockEdge(row++, 1, 0, timeStep_ns);
                else if (p_clk_i == 1 && top->clk_i == 0)
                    con->showClockEdge(row++, 1, 1, timeStep_ns);
                else
                    con->showClockEdge(row++, 1, 2, timeStep_ns);

                // if (ready_sig.changed())
                con->showIntProperty(row++, 1, "Ready", top->ready_o);

                con->showIntProperty(row++, 1, "Reset", top->reset_i);
                con->showCPUState(row++, 1, "State", cm->state);
                con->showVectorState(row++, 1, "Vec State", cm->vector_state);

                con->showIntAsHexProperty(row++, 1, "PC", pc->data_o);
                con->showIntProperty(row++, 1, "PC_ld", cm->pc_ld);
                con->showIntProperty(row++, 1, "PC_src", cm->pc_src);
                con->showIntAsHexProperty(row++, 1, "PC_src_out", risc->pc_src_out);

                con->showIntProperty(row++, 1, "Mem_wr", cm->mem_wr);
                con->showIntProperty(row++, 1, "Mem_rd", cm->mem_rd);
                con->showIntAsHexProperty(row++, 1, "Pmmu_out", risc->pmmu_out);
                con->showIntProperty(row++, 1, "Addr_src", cm->addr_src);
                con->showIntProperty(row++, 1, "Rst_src", cm->rst_src);

                con->showIntAsHexProperty(row++, 1, "IR", ir->data_o);

                p_clk_i = top->clk_i;
                stepCnt++;
                timeStep_ns++;
            }
        }

        con->update();

        if (delayEnabled)
            napms(timeStepDelayms);
    }

    delete con;

    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finishing TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}

// async futures
// https://devdreamz.com/question/844791-user-input-without-pausing-code-c-console-application
// https://forum.juce.com/t/async-input-stream/48817/4
// https://www.codeproject.com/Questions/5275669/How-can-I-use-input-without-waiting-user-to-give-s
// https://www.linuxquestions.org/questions/programming-9/how-do-i-watch-for-keyboard-input-without-waiting-in-c-858521/
// http://www.cplusplus.com/forum/general/242502/

// curses
// https://stackoverflow.com/questions/7772341/how-to-get-a-character-from-stdin-without-waiting-for-user-to-put-it
// http://www.c-faq.com/osdep/cbreak.html