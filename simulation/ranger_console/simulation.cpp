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
    // If we are already sitting at the Fetch state then we need to
    // move forward to the Decode state and then search.
    if (mdl.cm->state == mdl.unit->MatrixState::Fetch)
    {
        while (mdl.cm->state != mdl.unit->MatrixState::Decode)
        {
            begin(mdl);
            tb->eval();
            update(mdl);
        }
    }

    while (mdl.cm->state != mdl.unit->MatrixState::Fetch)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
    }
}

void Simulation::run_to_decode(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    // If we are already sitting at the Fetch state then we need to
    // move forward to the Execute state and then search.
    if (mdl.cm->state == mdl.unit->MatrixState::Decode)
    {
        while (mdl.cm->state != mdl.unit->MatrixState::Execute)
        {
            begin(mdl);
            tb->eval();
            update(mdl);
        }
    }

    while (mdl.cm->state != mdl.unit->MatrixState::Decode)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
    }
}

void Simulation::run_to_execute(Model &mdl, TESTBENCH<VRangerRisc> *tb)
{
    // If we are already sitting at the Fetch state then we need to
    // move forward to the Fetch state and then search.
    if (mdl.cm->state == mdl.unit->MatrixState::Execute)
    {
        while (mdl.cm->state != mdl.unit->MatrixState::Fetch)
        {
            begin(mdl);
            tb->eval();
            update(mdl);
        }
    }

    while (mdl.cm->state != mdl.unit->MatrixState::Execute)
    {
        begin(mdl);
        tb->eval();
        update(mdl);
    }
}
