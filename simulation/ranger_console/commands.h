#pragma once

enum class Command
{
    None,
    Exit,
    Reset,
    Stop,
    Run,
    NStep,  // nano timescale step
    HCStep, // half-cycle step
    FLStep, // full cycle step
    Signal,
    SetReg, // Activate a Regfile register
    EnableSim,
    EnableDelay,
    DelayTime,
    MemRange,
    MemModify,
    LoadProg,
};
