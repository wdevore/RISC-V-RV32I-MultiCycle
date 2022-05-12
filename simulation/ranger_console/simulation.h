#pragma once
#include <verilated.h>

#include "model.h"
#include "console_module.h"

class Simulation
{
private:
public:
    Simulation();
    ~Simulation();

    int init(void);

    void begin(Model &mdl);
    void update(Model &mdl);
    void end(Model &mdl);

    void begin_reset(Model &mdl);
    void update_reset(Model &mdl, TESTBENCH<VRangerRisc> *tb);
    void end_reset(Model &mdl);
};
