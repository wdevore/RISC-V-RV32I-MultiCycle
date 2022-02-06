#include <stdio.h>
#include <iostream>
#include <iomanip>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VPmmu.h"
// Needed for the exposed public fields via "*verilator public*"
// and Top module
#include "VPmmu___024root.h"
#include "VPmmu__Syms.h"

// Test bench files
#include "module.h"

extern bool assertionFailure;
extern unsigned long int wordToByteAddr(unsigned long int wordaddr);
extern int step(int timeStep, TESTBENCH<VPmmu> *tb, VPmmu___024root *top);

int sType_sw(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store word to word-address d4
    //    rs2   rs1 = x2 = 4
    // sw x14, 1(x2)    imm(x2) = 1(4)*(4 bytes) = d16
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    010      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   2     0    A   3
    // 0000 0000 1110 0001 0010 0000 1010 0011 = 0x00E120A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0;
    unsigned long int imm = 0;
    int selector = 0b00;
    assertionFailure = false;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b010;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            selector = 0b00; // not relevant for words
            rs1 = 4;
            rs2 = 0x0B0A0908; // The data to write
            imm = 0x00000001;
            top->wd_i = rs2;
            top->byte_addr_i = wordToByteAddr(imm * rs1) + selector;
        }

        if (timeStep == baseTime + 8)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 15)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x0B0A0908)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x0B0A0908, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}

int sType_sh_word1(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store half-word(0) to word-address d5
    //    rs2   rs1 = x2 = 5
    // sh x14, 1(x2)    imm(x2) = 1(5)*(4 bytes)
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    001      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   1     0    A   3
    // 0000 0000 1110 0001 0001 0000 1010 0011 = 0x00E110A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0; // x14 -- just for description.
    unsigned long int imm = 0;
    assertionFailure = false;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b001;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            rs1 = 5;
            rs2 = 0xAABBCCDD; // The data to write. Only CCDD should be written
            imm = 0x00000001;
            top->wd_i = rs2;
            top->mrd_i = 0; // Enable reading
            top->byte_addr_i = wordToByteAddr(imm * rs1);
        }

        if (timeStep == baseTime + 15)
        {
            top->mrd_i = 1; // Disable reading
        }

        if (timeStep == baseTime + 25)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 35)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x1111CCDD)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x1111CCDD, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}

int sType_sh_word2(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store half-word(0) to word-address d5 to upper word
    //    rs2   rs1 = x2 = 5
    // sh x14, 1(x2)    imm(x2) = 1(5)*(4 bytes)
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    001      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   1     0    A   3
    // 0000 0000 1110 0001 0001 0000 1010 0011 = 0x00E110A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0; // x14 -- just for description.
    unsigned long int imm = 0;
    assertionFailure = false;
    int selector = 0;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b001;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            rs1 = 5;
            rs2 = 0xAABB7788; // The data to write. Only 7788 should be written
            imm = 0x00000001;
            selector = 0b10;
            top->wd_i = rs2;
            top->mrd_i = 0; // Enable reading
            top->byte_addr_i = wordToByteAddr(imm * rs1) + selector;
        }

        if (timeStep == baseTime + 15)
        {
            top->mrd_i = 1; // Disable reading
        }

        if (timeStep == baseTime + 25)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 35)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x7788CCDD)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x7788CCDD, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}

int sType_sb_byte1(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store 1st byte to word-address d8
    //    rs2   rs1 = x2 = 8
    // sb x14, 1(x2)    imm(x2) = 1(8)*(4 bytes)
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    000      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   0     0    A   3
    // 0000 0000 1110 0001 0000 0000 1010 0011 = 0x00E100A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0; // x14 -- just for description.
    unsigned long int imm = 0;
    assertionFailure = false;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b000;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            rs1 = 8;
            rs2 = 0xAABBCCDD; // The data to write. Only DD should be written
            imm = 0x00000001;
            top->wd_i = rs2;
            top->mrd_i = 0; // Enable reading
            top->byte_addr_i = wordToByteAddr(imm * rs1);
        }

        if (timeStep == baseTime + 15)
        {
            top->mrd_i = 1; // Disable reading
        }

        if (timeStep == baseTime + 25)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 35)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x111111DD)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x111111DD, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}

int sType_sb_byte2(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store byte to word-address d8 2nd byte position
    //    rs2   rs1 = x2 = 8
    // sb x14, 1(x2)    imm(x2) = 1(8)*(4 bytes)
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    000      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   0     0    A   3
    // 0000 0000 1110 0001 0000 0000 1010 0011 = 0x00E100A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0; // x14 -- just for description.
    unsigned long int imm = 0;
    assertionFailure = false;
    int selector = 0;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b000;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            rs1 = 8;
            rs2 = 0x111111CC; // The byte to write. Only CC should be written
            imm = 0x00000001;
            selector = 0b01;
            top->wd_i = rs2;
            top->mrd_i = 0; // Enable reading
            top->byte_addr_i = wordToByteAddr(imm * rs1) + selector;
        }

        if (timeStep == baseTime + 15)
        {
            top->mrd_i = 1; // Disable reading
        }

        if (timeStep == baseTime + 25)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 35)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x1111CCDD)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x1111CCDD, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}

int sType_sb_byte3(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store byte to word-address d8 3rd byte position
    //    rs2   rs1 = x2 = 8
    // sb x14, 1(x2)    imm(x2) = 1(8)*(4 bytes)
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    000      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   0     0    A   3
    // 0000 0000 1110 0001 0000 0000 1010 0011 = 0x00E100A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0; // x14 -- just for description.
    unsigned long int imm = 0;
    assertionFailure = false;
    int selector = 0;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b000;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            rs1 = 8;
            rs2 = 0x11111133; // The byte to write. Only 33 should be written
            imm = 0x00000001;
            selector = 0b10;
            top->wd_i = rs2;
            top->mrd_i = 0; // Enable reading
            top->byte_addr_i = wordToByteAddr(imm * rs1) + selector;
        }

        if (timeStep == baseTime + 15)
        {
            top->mrd_i = 1; // Disable reading
        }

        if (timeStep == baseTime + 25)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 35)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x1133CCDD)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x1133CCDD, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}

int sType_sb_byte4(int timeStep, int baseTime, int duration, VPmmu_Memory *bram, VPmmu___024root *top, TESTBENCH<VPmmu> *tb)
{
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    // S-Type: Store byte to word-address d8 4th byte position
    //    rs2   rs1 = x2 = 8
    // sb x14, 1(x2)    imm(x2) = 1(8)*(4 bytes)
    // --**--**--**--**--**--**--**--**--**--**--**--**--**
    //    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
    //    0000000     01110  00010    000      00001     0100011
    //       |                                   |
    //        \----------- = 0x01 --------------/
    //   0    0    E    1   0     0    A   3
    // 0000 0000 1110 0001 0000 0000 1010 0011 = 0x00E100A3

    unsigned long int rs1 = 0;
    unsigned long int rs2 = 0; // x14 -- just for description.
    unsigned long int imm = 0;
    assertionFailure = false;
    int selector = 0;

    while (timeStep <= baseTime + duration)
    {
        if (timeStep - 1 == baseTime)
        {
            top->funct3 = 0b000;
            top->mwr_i = 1; // Disable writing/storing
        }

        if (timeStep == baseTime + 5)
        {
            rs1 = 8;
            rs2 = 0x11111144; // The byte to write. Only 44 should be written
            imm = 0x00000001;
            selector = 0b11;
            top->wd_i = rs2;
            top->mrd_i = 0; // Enable reading
            top->byte_addr_i = wordToByteAddr(imm * rs1) + selector;
        }

        if (timeStep == baseTime + 15)
        {
            top->mrd_i = 1; // Disable reading
        }

        if (timeStep == baseTime + 25)
        {
            top->mwr_i = 0; // Enable writing/storing
        }

        if (timeStep == baseTime + 35)
        {
            top->mwr_i = 1; // Disable writing/storing
        }

        timeStep = step(timeStep, tb, top);
    }

    // Test assertion
    int cell = bram->mem[imm * rs1];
    if (cell != 0x4433CCDD)
    {
        std::cout << "###########################################" << std::endl;
        std::cout << "# expected BRAM[4] = 0x4433CCDD, got: " << std::hex << cell << std::endl;
        std::cout << "###########################################" << std::endl;
        assertionFailure = true;
    }

    return timeStep;
}
