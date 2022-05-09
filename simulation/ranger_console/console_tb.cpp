#include <stdio.h>
#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "commands.h"
#include "row_indices.h"
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
    VRangerRisc_Register *pc_prior = risc->pc_prior;
    VRangerRisc_Register *mdr = risc->mdr;
    VRangerRisc_Mux4 *wd_mux = risc->wd_mux;
    VRangerRisc_Register *rsa = risc->rsa;
    VRangerRisc_Register *rsb = risc->rsb;
    VRangerRisc_Register *alu_out = risc->alu_out_rg;
    VRangerRisc_Register__D4 *alu_flags = risc->alu_flags_rg;

    VRangerRisc_RegisterFile *regFile = risc->reg_file;

    VRangerRisc_Mux4 *a_mux = risc->a_mux;
    VRangerRisc_Mux4 *b_mux = risc->b_mux;

    VRangerRisc_ALU__D20 *alu = risc->alu;
    VRangerRisc_Immediate *imm_ext = risc->imm_ext;

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
    // bool simEnabled = true;
    bool simRunning = false;

    // --------------------------------------------------
    // initialize NCurses
    // --------------------------------------------------
    Console *con = new Console();
    con->init();

    con->start();

    con->showULIntProperty(+RowPropId::Timestep, 1, "timeStep(ns)", timeStep_ns);
    con->showBoolProperty(+RowPropId::SimRunning, 1, "Sim running", false);
    con->showIntProperty(+RowPropId::DelayTime, 1, "Delay time", timeStepDelayms);
    con->showIntProperty(+RowPropId::StepSize, 1, "Step size", stepSize);
    con->showClockEdge(+RowPropId::ClockEdge, 1, 2, timeStep_ns);
    con->showIntProperty(+RowPropId::Ready, 1, "Ready", cm->ready);
    con->showIntProperty(+RowPropId::Reset, 1, "Reset", top->reset_i);
    con->showCPUState(+RowPropId::State, 1, "State", cm->state);
    con->showCPUState(+RowPropId::NxState, 1, "Nxt State", cm->vector_state);
    con->showVectorState(+RowPropId::VecState, 1, "Vec State", cm->vector_state);
    con->showVectorState(+RowPropId::NxVecState, 1, "Nxt Vec-State", cm->next_vector_state);

    // Default to "not" holding CPU in reset state. Reset is active low.
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

            if (con->getArg1() == "reset")
                con->showIntProperty(+RowPropId::Reset, 1, "Reset", top->reset_i);
            break;
        case Command::NStep:
            stepCnt = 0;
            stepSize = 1;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", stepSize);
            break;
        case Command::HCStep:
            stepCnt = 0;
            stepSize = halfCycle;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", stepSize);
            break;
        case Command::FLStep:
            stepCnt = 0;
            stepSize = fullCycle;
            con->showIntProperty(+RowPropId::StepSize, 1, "Step size", stepSize);
            break;
        case Command::SetReg:
            con->markForUpdate();
            break;
        case Command::EnableDelay:
            delayEnabled = con->getArg1Bool();
            break;
        case Command::DelayTime:
            timeStepDelayms = con->getArg1Int();
            con->showIntProperty(+RowPropId::DelayTime, 1, "Delay time", timeStepDelayms);
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
        if (stepCnt < stepSize)
        {
            // The clock toggles every half-cycle
            if (timeStep_ns % halfCycle == 0)
                top->clk_i ^= 1;

            timeStep_ns = tb->eval(timeStep_ns); // each eval() is 1 "timescale" = 1ns

            ready_sig.set(top->ready_o, timeStep_ns);

            con->showULIntProperty(+RowPropId::Timestep, 1, "timeStep(ns)", timeStep_ns);
            con->showBoolProperty(+RowPropId::SimRunning, 1, "Sim running", true);

            // Clock edges
            if (p_clk_i == 0 && top->clk_i == 1)
                con->showClockEdge(+RowPropId::ClockEdge, 1, 0, timeStep_ns);
            else if (p_clk_i == 1 && top->clk_i == 0)
                con->showClockEdge(+RowPropId::ClockEdge, 1, 1, timeStep_ns);
            else
                con->showClockEdge(+RowPropId::ClockEdge, 1, 2, timeStep_ns);

            // if (ready_sig.changed())
            con->showIntProperty(+RowPropId::Ready, 1, "Ready", top->ready_o);

            con->showIntProperty(+RowPropId::Reset, 1, "Reset", top->reset_i);

            con->showCPUState(+RowPropId::State, 1, "State", cm->state);
            con->showCPUState(+RowPropId::NxState, 1, "Nxt State", cm->next_state);
            con->showVectorState(+RowPropId::VecState, 1, "Vec-State", cm->vector_state);
            con->showVectorState(+RowPropId::NxVecState, 1, "Nxt Vec-State", cm->next_vector_state);

            con->showIntAsHexProperty(+RowPropId::PC, 1, "PC", pc->data_o);
            con->showIntAsHexProperty(+RowPropId::PCPrior, 1, "PC-prior", pc_prior->data_o);
            con->showIntProperty(+RowPropId::PC_LD, 1, "PC_ld", cm->pc_ld);
            con->showIntProperty(+RowPropId::PC_SRC, 1, "PC_src", cm->pc_src);
            con->showIntAsHexProperty(+RowPropId::PC_SRC_OUT, 1, "PC_src_out", risc->pc_src_out);

            con->showIntProperty(+RowPropId::MEM_WR, 1, "Mem_wr", cm->mem_wr);
            con->showIntProperty(+RowPropId::MEM_RD, 1, "Mem_rd", cm->mem_rd);
            con->showIntAsHexProperty(+RowPropId::PMMU_OUT, 1, "Pmmu_out", risc->pmmu_out);
            con->showIntAsHexProperty(+RowPropId::RSA_OUT, 1, "RsA", rsa->data_o);
            con->showIntAsHexProperty(+RowPropId::RSB_OUT, 1, "RsB", rsb->data_o);
            con->showIntAsHexProperty(+RowPropId::MDR, 1, "MDR", mdr->data_o);
            con->showIntProperty(+RowPropId::ADDR_SRC, 1, "Addr_src", cm->addr_src);
            con->showIntProperty(+RowPropId::RST_SRC, 1, "Rst_src", cm->rst_src);

            con->showIntProperty(+RowPropId::IR_LD, 1, "IR_ld", ir->ld_i);
            con->showIntAsHexProperty(+RowPropId::IR, 1, "IR", ir->data_o);

            con->showIntProperty(+RowPropId::WD_SRC, 1, "WD_src", wd_mux->select_i);
            con->showIntAsHexProperty(+RowPropId::WD_SRC_OUT, 1, "WD_Src_Out", wd_mux->data_o);

            con->showIntProperty(+RowPropId::A_SRC, 1, "A_src", a_mux->select_i);
            con->showIntAsHexProperty(+RowPropId::A_MUX_OUT, 1, "A_Mux_Out", a_mux->data_o);
            con->showIntProperty(+RowPropId::B_SRC, 1, "B_src", b_mux->select_i);
            con->showIntAsHexProperty(+RowPropId::B_MUX_OUT, 1, "B_Mux_Out", b_mux->data_o);

            con->showIntAsHexProperty(+RowPropId::IMM_EXT_OUT, 1, "IMM_Ext_Out", imm_ext->imm_o);

            con->showALUOp(+RowPropId::ALU_OP, 1, "ALUOp", alu->func_op_i);
            con->showIntAsHexProperty(+RowPropId::ALU_IMM_OUT, 1, "ALU_Imm_Out", alu->y_o);
            con->showIntProperty(+RowPropId::ALU_LD, 1, "ALU_ld", alu_out->ld_i);
            con->showIntAsHexProperty(+RowPropId::ALU_OUT, 1, "ALU_Out", alu_out->data_o);
            con->showIntProperty(+RowPropId::ALU_FLAGS_LD, 1, "ALU_flgs_ld", alu_flags->ld_i);
            con->showALUFlagsProperty(+RowPropId::ALU_FLAGS, 1, "ALU_Flags", alu_flags->data_o);

            con->showRegFile(2, 50, regFile->bank);

            p_clk_i = top->clk_i;

            stepCnt++;
            timeStep_ns++;
        }
        else
            con->showBoolProperty(+RowPropId::SimRunning, 1, "Sim running", false);

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