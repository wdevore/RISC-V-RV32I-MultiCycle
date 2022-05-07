#include <stdio.h>
#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "commands.h"
#include "console.h"

#define ESC '\x1B'

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

    VRangerRisc_Pmmu *pmmu = risc->pmmu;
    VRangerRisc_Memory *bram = pmmu->bram;

    // Not really useful for the most part.
    // VRangerRisc__Syms *vlSymsp = risc->vlSymsp;

    vluint64_t timeStep_ns = 0;

    // Allow any initial blocks to execute
    timeStep_ns = tb->eval(timeStep_ns); // each eval() is 1 "timescale" = 1ns

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

    bool running = false;
    bool looping = true;
    bool clockEnabled = true;

    // Disabling the sim means bypassing the call to eval();
    bool simEnabled = false;
    bool resetEnabled = true;

    // --------------------------------------------------
    // initialize NCurses
    // --------------------------------------------------
    Console *con = new Console();
    con->init();

    con->start();

    while (looping)
    {
        // ---------------------------------------------------
        // Handle Input
        // ---------------------------------------------------
        Command cmd = con->handleInput();

        switch (cmd)
        {
        case Command::Reset:
            timeStep_ns = 0;
            // Enable cpu reset pin and wait for reset-complete
            top->reset_i = 0;
            con->markForUpdate();
            break;
        case Command::NStep:
            timeStep_ns++;
            con->markForUpdate();
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
        if (simEnabled)
        {
            timeStep_ns = tb->eval(timeStep_ns); // each eval() is 1 "timescale" = 1ns
            // The clock toggles every half-cycle
            if (timeStep_ns % halfCycle == 0)
                top->clk_i ^= 1;
            con->markForUpdate();
        }

        con->showTimeStep(timeStep_ns);
        con->update();
    }

    delete con;

    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finishing TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}

// The core must be able to free-run

// 1) add shutdown cmd
// 2) add clock stop

// async futures
// https://devdreamz.com/question/844791-user-input-without-pausing-code-c-console-application
// https://forum.juce.com/t/async-input-stream/48817/4
// https://www.codeproject.com/Questions/5275669/How-can-I-use-input-without-waiting-user-to-give-s
// https://www.linuxquestions.org/questions/programming-9/how-do-i-watch-for-keyboard-input-without-waiting-in-c-858521/
// http://www.cplusplus.com/forum/general/242502/

// curses
// https://stackoverflow.com/questions/7772341/how-to-get-a-character-from-stdin-without-waiting-for-user-to-put-it
// http://www.c-faq.com/osdep/cbreak.html