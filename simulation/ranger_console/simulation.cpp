#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "simulation.h"
#include "commands.h"
#include "utils.h"

Simulation::Simulation(TESTBENCH<VRangerRisc> *tb, Console *con)
{
    this->cpu = tb->core();
    this->con = con;

    // The top module "RangerRisc"
    top = cpu->rootp;

    // Provides access to the sub-modules either privately or publicly.
    risc = top->RangerRisc;

    // The sub-modules
    cm = risc->matrix;
    ir = risc->ir;
    pc = risc->pc;
    pc_prior = risc->pc_prior;
    mdr = risc->mdr;
    wd_mux = risc->wd_mux;
    rsa = risc->rsa;
    rsb = risc->rsb;
    alu_out = risc->alu_out_rg;
    alu_flags = risc->alu_flags_rg;

    regFile = risc->reg_file;

    a_mux = risc->a_mux;
    b_mux = risc->b_mux;

    alu = risc->alu;
    imm_ext = risc->imm_ext;

    pmmu = risc->pmmu;
    bram = pmmu->bram;
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
    fromAddr = 0;
    p_pcMarker = 0;

    top->reset_i = 0;
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
