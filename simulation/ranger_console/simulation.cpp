#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "VRangerRisc___024unit.h"

#include "simulation.h"
#include "commands.h"
#include "utils.h"

Simulation::Simulation()
{
}

Simulation::~Simulation()
{
}

int Simulation::init(void)
{

    return 0;
}

// ----------------------------------------------------
// Reset sequencce
// ----------------------------------------------------
void Simulation::begin_reset(Model &mdl)
{
    mdl.simRunning = true;
    mdl.top->reset_i = 0;
    mdl.timeStep_ns = 0;
    mdl.stepCnt = 0;
    mdl.resetActive = true;
}

void Simulation::update_reset(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    // Toggle clock at least 3 times to create a large window
    // for syncing.
    int stepSize = mdl.fullCycle * 3;
    do
    {
        begin(mdl);
        tb->eval();
        update(mdl);
    } while (mdl.stepCnt < stepSize);

    mdl.resetActive = false;
}

void Simulation::end_reset(Model &mdl)
{
    mdl.simRunning = false;
    mdl.top->reset_i = 1;
}

// ----------------------------------------------------
// Standard stepping
// ----------------------------------------------------
void Simulation::begin(Model &mdl)
{
    mdl.simRunning = true;

    // The clock toggles every half-cycle
    if (mdl.timeStep_ns % mdl.halfCycle == 0)
        mdl.top->clk_i ^= 1;
}
void Simulation::update(Model &mdl)
{
    mdl.p_clk_i = mdl.top->clk_i;

    mdl.stepCnt++;
    mdl.timeStep_ns++;
}
void Simulation::end(Model &mdl)
{
    mdl.simRunning = false;
}

// ----------------------------------------------------
// Run until Fetch state reached
// ----------------------------------------------------
void Simulation::run_to_fetch(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    const int maxSteps = 100000;
    int cnt = 0;

    // If we are already sitting at the Fetch state then we need to
    // move forward to the Decode state and then search.
    if (mdl.cm->state == mdl.unit->MatrixState::Fetch)
    {
        while (mdl.cm->state != mdl.unit->MatrixState::Decode && cnt < maxSteps)
        {
            begin(mdl);
            tb->eval();
            update(mdl);
            cnt++;
        }
    }

    cnt = 0;
    while (mdl.cm->state != mdl.unit->MatrixState::Fetch && cnt < maxSteps)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
        cnt++;
    }
}

void Simulation::run_to_decode(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    const int maxSteps = 100000;
    int cnt = 0;

    // If we are already sitting at the Fetch state then we need to
    // move forward to the Execute state and then search.
    if (mdl.cm->state == mdl.unit->MatrixState::Decode && cnt < maxSteps)
    {
        while (mdl.cm->state != mdl.unit->MatrixState::Execute)
        {
            begin(mdl);
            tb->eval();
            update(mdl);
            cnt++;
        }
    }

    cnt = 0;
    while (mdl.cm->state != mdl.unit->MatrixState::Decode && cnt < maxSteps)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
        cnt++;
    }
}

void Simulation::run_to_execute(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    const int maxSteps = 100000;
    int cnt = 0;

    // If we are already sitting at the Fetch state then we need to
    // move forward to the Fetch state and then search.
    if (mdl.cm->state == mdl.unit->MatrixState::Execute)
    {
        while (mdl.cm->state != mdl.unit->MatrixState::Fetch && cnt < maxSteps)
        {
            begin(mdl);
            tb->eval();
            update(mdl);
            cnt++;
        }
    }

    cnt = 0;
    while (mdl.cm->state != mdl.unit->MatrixState::Execute && cnt < maxSteps)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
        cnt++;
    }
}

void Simulation::run_to_ebreak(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    // Code is: 7'b1110011
    // if (ir_i[20] == 1'b1)
    //    next_ir_state = ITEbreak;
    std::string ir;
    std::string opCode;

    // string is:      0 -> 31
    // instruction is: 31 -> 0
    // Scan for 100000ns max
    for (int i = 0; i < 100000; i++)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
        ir = int_to_bin(mdl.ir->data_o, "");
        opCode = ir.substr(ir.size() - 7, ir.size() - 1);
        if (opCode == "1110011" && ir[11] == '1')
        {
            // mvaddstr(0, 100, opCode.c_str());
            break;
        }
    }
}
