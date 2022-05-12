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

void Simulation::begin_reset(void)
{
}

void Simulation::reset(void)
{
    // Track time and update tb sim
}

void Simulation::end_reset(void)
{
    top->reset_i = 1;
}

void Simulation::update(void)
{
}
