#include <stdio.h>
#include <iostream>
#include <fstream>
#include <regex>

#include <ncurses.h>

#include "commands.h"
#include "row_indices.h"
#include "console.h"
#include "model.h"
#include "simulation.h"

#include "property.h"
#include "utils.h"

#include <verilated.h>
#include <verilated_vcd_c.h>

// Files generated by Verilator
#include "VRangerRisc.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VRangerRisc__Syms.h"
#include "VRangerRisc_Memory.h"

// Test bench files
#include "console_module.h"

#define ACTIVE_SIG 0
#define INACTIVE_SIG 1
#define CLOCK_HIGH 1
#define CLOCK_LOW 0

int main(int argc, char *argv[])
{
    // --------------------------------------------------
    // initialize Verilog (aka SystemVerilog) module
    // --------------------------------------------------
    Verilated::commandArgs(argc, argv);

    TESTBENCH<VRangerRisc> *tb = new TESTBENCH<VRangerRisc>();

    tb->setup();

    VRangerRisc *cpu = tb->core();

    Model mdl{cpu};

    // Default to clock low
    mdl.top->clk_i = CLOCK_LOW;

    // Allow any initial blocks to execute (timeStep 0->1)
    tb->eval(); // each eval() is 1 "time unit" = 1ns
    mdl.timeStep_ns++;

    // Each timescale step can be delayed
    // For example, if the HDL step is 1ns then each
    // 1ns step will occur every 10ms.
    bool delayEnabled = true;

    bool looping = true;

    // Disabling the sim means bypassing the call to eval();
    bool simRunning = false;

    // --------------------------------------------------
    // initialize NCurses
    // --------------------------------------------------
    Console *con = new Console();
    con->init();

    con->start();

    con->show(mdl);

    // Default to "not" holding CPU in reset state. Reset is active low.
    mdl.top->reset_i = INACTIVE_SIG;

    Simulation sim = Simulation{};

    con->showMemory(2, 70, mdl.fromAddr, 1024, mdl.bram->mem);

    while (looping)
    {
        Command cmd = con->handleInput();

        switch (cmd)
        {
        case Command::Signal:
            if (con->getArg1() == "reset")
            {
                // Enable cpu reset pin and wait for reset-complete
                mvaddstr(0, 100, "--- Resetting ---");
                sim.begin_reset(mdl);
                sim.update_reset(mdl, tb);
                sim.end_reset(mdl);
                con->show(mdl);
            }
            break;
        case Command::RunTo:
            if (con->getArg1() == "fetch" || con->getArg1() == "fe")
            {
                sim.run_to_fetch(mdl, tb);
            }
            else if (con->getArg1() == "decode" || con->getArg1() == "de")
            {
                sim.run_to_decode(mdl, tb);
            }
            else if (con->getArg1() == "execute" || con->getArg1() == "ex")
            {
                sim.run_to_execute(mdl, tb);
            }
            else if (con->getArg1() == "ebreak" || con->getArg1() == "eb")
            {
                sim.run_to_ebreak(mdl, tb);
            }
            else if (con->getArg1() == "pc")
            {
                mdl.targetPC = word_to_byte_addr(con->getArg2Int());
                sim.run_to_pc(mdl, tb);
            }

            con->show(mdl);
            break;
        case Command::NStep:
            mdl.stepCnt = 0;
            mdl.stepSize = 1;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", mdl.stepSize);
            break;
        case Command::HCStep:
            mdl.stepCnt = 0;
            mdl.stepSize = mdl.halfCycle;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", mdl.stepSize);
            break;
        case Command::FLStep:
            mdl.stepCnt = 0;
            mdl.stepSize = mdl.fullCycle;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", mdl.stepSize);
            break;
        case Command::SetStepSize:
            mdl.stepCnt = 0;
            mdl.stepSize = con->getArg1Int();
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", mdl.stepSize);
            break;
        case Command::Halt:
            mdl.stepCnt = 0;
            mdl.stepSize = 0;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", mdl.stepSize);
            break;
        case Command::MemRange:
        {
            mdl.fromAddr = con->getArg1Int();
            con->showMemory(2, 70, mdl.fromAddr, 1024, mdl.bram->mem);
        }
        break;
        case Command::MemModify:
        {
            mdl.memAddr = con->getArg1Int();

            int value = con->getArg2Int();

            mdl.bram->mem[mdl.memAddr] = value;
            con->showMemory(2, 70, mdl.fromAddr, 1024, mdl.bram->mem);
        }
        break;
        case Command::MemScrollUp:
            // Dec address
            mdl.fromAddr--;
            if (mdl.fromAddr < 0)
                mdl.fromAddr = 0;

            con->showPCMarker(mdl);

            con->showMemory(2, 70, mdl.fromAddr, 1024, mdl.bram->mem);
            break;
        case Command::MemScrollDwn:
            // Inc address
            mdl.fromAddr++;
            if (mdl.fromAddr > 1023)
                mdl.fromAddr = 1023;
            con->showPCMarker(mdl);

            con->showMemory(2, 70, mdl.fromAddr, 1024, mdl.bram->mem);
            break;
        case Command::SetReg:
            mdl.selectedReg = con->getArg1Int();
            con->showRegisterBin(37, 40, "Reg", mdl.regFile->bank[mdl.selectedReg]);
            break;
        case Command::SetPC:
        {
            // Note: I set the output even though during simulation
            // you would set the input, load and clock falling edge.
            mdl.pc->data_o = con->getArg1Int();

            con->showIntAsHexProperty(+RowPropId::PC, 1, "PC", mdl.pc->data_o);

            // Update PC marker
            con->showPCMarker(mdl);
        }
        break;
        case Command::LoadProg:
        {
            // Load ram into memory
            std::string line;
            std::string fileName = "rams/" + con->getArg1() + ".ram";
            std::ifstream file(fileName);

            if (file.is_open())
            {
                std::string msg = "Opened: " + fileName;
                move(0, 50);
                clrtoeol();
                mvaddstr(0, 50, msg.c_str());

                // Ex: @01 00100073
                std::smatch matches;
                std::regex mem_regex("@([a-fA-F0-9]+) ([a-fA-F0-9]{8})");

                while (getline(file, line))
                {
                    // Parse and set memory
                    if (std::regex_search(line, matches, mem_regex))
                    {
                        if (matches.size() > 2)
                        {
                            // [0] is the line itself.
                            std::string maddr = matches[1].str();
                            std::string mval = matches[2].str();

                            // Convert data from hex to int
                            int addr = hex_string_to_int(maddr);
                            int val = hex_string_to_int(mval);
                            mdl.bram->mem[addr] = val;
                        }
                    }
                    else
                    {
                        mvaddstr(0, 100, "No match!!!!!!!!!!!");
                    }
                }

                file.close();
            }
            else
            {
                std::string msg = "Unable to open: " + fileName;
                move(0, 50);
                clrtoeol();
                mvaddstr(0, 50, msg.c_str());
            }

            con->showMemory(2, 70, mdl.fromAddr, 1024, mdl.bram->mem);
        }
        break;
        case Command::EnableDelay:
            delayEnabled = con->getArg1Bool();
            break;
        case Command::DelayTime:
            mdl.timeStepDelayms = con->getArg1Int();
            con->showIntProperty(+RowPropId::DelayTime, 1, "Delay time", mdl.timeStepDelayms);
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
        if (mdl.stepCnt < mdl.stepSize)
        {
            sim.begin(mdl);

            tb->eval(); // each eval() is 1 "time-unit" = 1ns

            con->show(mdl);

            sim.update(mdl);
        }
        else
        {
            sim.end(mdl);
            con->showBoolProperty(+RowPropId::SimRunning, 1, "Sim running", mdl.simRunning);
        }

        con->update();

        if (delayEnabled)
            napms(mdl.timeStepDelayms);
    }

    delete con;

    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finishing TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}

// Tasks:
// add run to PC
// Add mem mapped IO and interrupts
// Or UART as a blackbox

// - add run to Flag set
// - J (jump) command. Sets PC to address.
//    - Call (???)

// - UART or PIO
// This requires a plain testbench that interacts solely with a terminal

// async futures
// https://devdreamz.com/question/844791-user-input-without-pausing-code-c-console-application
// https://forum.juce.com/t/async-input-stream/48817/4
// https://www.codeproject.com/Questions/5275669/How-can-I-use-input-without-waiting-user-to-give-s
// https://www.linuxquestions.org/questions/programming-9/how-do-i-watch-for-keyboard-input-without-waiting-in-c-858521/
// http://www.cplusplus.com/forum/general/242502/

// curses
// https://stackoverflow.com/questions/7772341/how-to-get-a-character-from-stdin-without-waiting-for-user-to-put-it
// http://www.c-faq.com/osdep/cbreak.html

// coredumps:
// ulimit -c unlimited
// gdb /media/RAMDisk/VRangerRisc
//    backtrace
