#pragma once

#include "commands.h"

class Console
{
private:
    std::string keyBuffer;
    std::string lastCmd;
    char ch;
    const int startCmdLineCol = 1; // Caret starts at column
    int col = startCmdLineCol;
    bool dataDirty = true;

    bool _exitConsole = false;
    Command cmd;

public:
    Console(/* args */);
    ~Console();

    int init(void);
    Command handleInput();
    void start(void);
    void update(void);
    bool exitConsole(void);
    void markForUpdate(void);

    std::string getCmd(void);

    void clearCmdLine(void);
    void showTermCaret(void);
    void moveCaretToEndl(void);

    void showTimeStep(unsigned long int timeStep);
};
