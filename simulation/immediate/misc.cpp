#include <stdio.h>
#include <iostream>
#include <iomanip>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VImmediate.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VImmediate___024root.h"
#include "VImmediate__Syms.h"

// Test bench files
#include "module.h"

int step(int timeStep, TESTBENCH<VImmediate> *tb, VImmediate___024root *top)
{
    tb->eval();
    tb->dump(timeStep);

    timeStep++;

    return timeStep;
}

void abort(TESTBENCH<VImmediate> *tb)
{
    tb->shutdown();

    delete tb;

    exit(EXIT_FAILURE);
}