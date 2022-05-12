#include <iostream>
#include <iomanip>

#include <ncurses.h>

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
    // Track time and update tb sim
    // Toggle clock at least 3 times for reset signal take hold
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
