#pragma once

#include <stdio.h>
#include <iostream>
#include <iomanip>

template <class MODULE>
class TESTBENCH
{
private:
    MODULE *_core;

public:
    TESTBENCH(void)
    {
        _core = new MODULE;
    }

    virtual ~TESTBENCH(void)
    {
        delete _core;
        _core = NULL;
    }

    virtual void setup(void)
    {
        // std::cout << "Setting up" << std::endl;
    }

    virtual void shutdown(void)
    {
        std::cout << "Shutting down" << std::endl;
        _core->final(); // simulation done
    }

    virtual void eval(void)
    {
        // Update simulation
        _core->eval();
    }

    virtual MODULE *core(void)
    {
        return _core;
    }

    virtual bool done(void) { return (Verilated::gotFinish()); }
};