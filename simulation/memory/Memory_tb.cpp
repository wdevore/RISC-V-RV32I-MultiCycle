#include <stdio.h>
#include <iostream>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VMemory.h"

// Test bench files
#include "module.h"

// This file is similar to a Verilog test bench file except
// is C++
int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    // initialize Verilog module
    TESTBENCH<VMemory> *tb = new TESTBENCH<VMemory>();

    tb->setup();

    tb->show();

    VMemory *mem = tb->core();

    mem->write_en_ni = 1; // disable writing
    mem->clk_i = 0;
    tb->sampletick();

    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // Read memory at 0x0
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    mem->address_i = 0;
    mem->clk_i ^= 1;
    tb->sampletick();

    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // Read memory at 0x2
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    mem->address_i = 2;
    mem->clk_i ^= 1;
    tb->sampletick();
    mem->clk_i ^= 1;
    tb->sampletick();

    // Padding
    mem->clk_i ^= 1;
    tb->sampletick();

    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // Write 0x0000A0A0 to memory at 0x5
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    mem->write_en_ni = 0; // enable writing
    mem->data_i = 0x0000A0A0;
    mem->address_i = 5;
    mem->clk_i ^= 1; // Rising
    tb->sampletick();

    // Setup for read and change input to Zero for clarity
    mem->data_i = 0x00000000;
    mem->write_en_ni = 1; // disable writing
    mem->clk_i ^= 1;      // Falling
    tb->sampletick();

    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // Read memory back at 0x5
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    mem->clk_i ^= 1;
    tb->sampletick(); // Rising
    mem->clk_i ^= 1;
    tb->sampletick(); // Falling

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}
