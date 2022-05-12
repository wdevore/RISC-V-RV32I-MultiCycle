#pragma once
#include <verilated.h>

#include "commands.h"
#include "model.h"

class Console
{
private:
    std::string keyBuffer;
    std::string lastCmd;
    int ch;
    const int startCmdLineCol = 1; // Caret starts at column
    int col = startCmdLineCol;
    bool dataDirty = true;

    bool _exitConsole = false;
    Command cmd;
    std::string arg1;
    std::string arg2;
    std::string arg3;
    std::string arg4;
    std::string arg5;

    int p_clkState = 1;

    void _showLabel(int row, int col, std::string label);

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

    const std::string &getArg1(void);
    long int getArg1Int(void);
    long int getArg2Int(void);
    bool getArg1Bool(void);

    const std::string &getArg2(void);
    const std::string &getArg3(void);
    const std::string &getArg4(void);
    const std::string &getArg5(void);

    void clearCmdLine(void);
    void showTermCaret(void);
    void moveCaretToEndl(void);

    void show(Model& mdl);

    void showULIntProperty(int row, int col, std::string lable, unsigned long int value);
    void showIntProperty(int row, int col, std::string lable, int value, int when = -1);
    void showIntAsHexProperty(int row, int col, std::string lable, int value, int when = -1);
    void showBoolProperty(int row, int col, std::string lable, bool value);
    void showRegisterBin(int row, const std::string &header, int value);

    void showClockEdge(int row, int col, int clkState, int when);

    void showCPUState(int row, int col, std::string label, int value);
    void showVectorState(int row, int col, std::string label, int value);
    void showIRState(int row, int col, std::string label, int value);
    void showALUOp(int row, int col, std::string label, int value);
    void showALUFlagsProperty(int row, int col, std::string label, int value);
    void showRegFile(int row, int col, VlUnpacked<IData, 32> values);
    void showMemory(int row, int col, long int fromAddr, int memLen, VlUnpacked<IData, 1024> mem);
    // int showPCMarker(int pcMarkerRow, int markerCol, int rowOffset, int pc, long int fromAddr);
    void showPCMarker(Model& model);
};
