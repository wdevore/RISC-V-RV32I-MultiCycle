#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "console.h"
#include "commands.h"
#include "utils.h"

Console::Console(/* args */)
{
    initscr();
}

Console::~Console()
{
    std::cout << "Shutting down console" << std::endl;
    endwin();
}

int Console::init(void)
{
    // Configure ncurses for non-blocking, no chars echoed
    raw();
    noecho();
    keypad(stdscr, true);  // Include control sequences
    nodelay(stdscr, true); // Enable non-blocking

    // Check for Terminal features.
    if (!has_colors())
    {
        endwin();
        puts("Term can't do colors");
        return 1;
    }

    if (start_color() != OK)
    {
        endwin();
        puts("Term can't start colors");
        return 1;
    }

    if (can_change_color() != OK)
    {
        puts("Term can't change colors");
    }

    return 0;
}

void Console::update(void)
{
    if (dataDirty)
    {
        showTermCaret();

        moveCaretToEndl();

        refresh();

        dataDirty = false;
    }
}

void Console::markForUpdate(void)
{
    dataDirty = true;
}

void Console::start(void)
{
    addstr("----- RangerRisc Console -----");

    clearCmdLine();
    showTermCaret();
    moveCaretToEndl();
}

bool Console::exitConsole()
{
    return _exitConsole;
}

Command Console::handleInput()
{
    ch = getch();

    cmd = Command::None;

    if (ch == '`')
    {
        // Exit application
        _exitConsole = true;
        return Command::Exit;
    }
    else if (ch == KEY_BACKSPACE)
    {
        if (col > 1)
        {
            move(LINES - 1, col);
            addch(' ' | A_NORMAL);
            col--;
            keyBuffer = keyBuffer.substr(0, keyBuffer.size() - 1);
            dataDirty = true;
        }
    }
    else if (ch == '\n')
    {
        col = startCmdLineCol;
        move(LINES - 1, col);

        // If the user hit return on a blank line then repeat previous command
        if (keyBuffer == "")
            keyBuffer = lastCmd;

        // If there was no previous command then skip everything
        if (keyBuffer == "")
            return Command::None;

        if (keyBuffer == "reset")
        {
            cmd = Command::Reset;
        }
        else if (keyBuffer.rfind("sig", 0) == 0)
        {
            // Ex: sig reset h
            cmd = Command::Signal;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields[1]; // reset, ...
            arg2 = fields[2]; // (l)ow/(h)igh
        }
        else if (keyBuffer == "ns")
            cmd = Command::NStep;
        else if (keyBuffer == "hc")
            cmd = Command::HCStep;
        else if (keyBuffer == "fl")
            cmd = Command::FLStep;
        else if (keyBuffer.rfind("delay", 0) == 0)
        {
            cmd = Command::EnableDelay;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "off";
        }
        else if (keyBuffer.rfind("dtime", 0) == 0)
        {
            cmd = Command::DelayTime;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "10";
        }
        else if (keyBuffer.rfind("srg", 0) == 0)
        {
            cmd = Command::SetReg;
            // Make a Regfile register as active
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "0";
        }
        else if (keyBuffer.rfind("mr", 0) == 0)
        {
            // Set memory display range
            cmd = Command::MemRange;
            // Make a Regfile register as active
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "0"; // From
            int to = string_to_int(arg1) + 32;
            arg2 = fields.size() > 2 ? fields[2] : int_to_string(to); // To
        }

        dataDirty = true;

        lastCmd = keyBuffer;
        clearCmdLine();
        keyBuffer.clear(); // Clear command now that we have used it
    }
    else if (ch >= ' ' && ch < '~')
    {
        // Allow all ascii chars
        col++;
        move(LINES - 1, col);
        addch(ch | A_NORMAL);
        keyBuffer.push_back(ch);
        dataDirty = true;
    }

    return cmd;
}

void Console::clearCmdLine(void)
{
    move(LINES - 1, 2);
    clrtoeol();
}

void Console::showTermCaret(void)
{
    attrset(A_NORMAL);
    mvaddch(LINES - 1, 1, '>');
}

void Console::moveCaretToEndl(void)
{
    move(LINES - 1, col + 1);
}

// --------------------------------------------------------------------
// Show methods
// --------------------------------------------------------------------
void Console::_showLabel(int row, int col, std::string label)
{
    dataDirty = true;
    attrset(A_NORMAL);
    move(row, col);
    printw("                        ");
    move(row, col);
    printw("%s: ", label.c_str());
    attrset(A_BOLD);
}

void Console::showULIntProperty(int row, int col, std::string label, unsigned long int value)
{
    _showLabel(row, col, label);
    printw("%d", value);
}

void Console::showIntProperty(int row, int col, std::string label, int value, int when)
{
    _showLabel(row, col, label);
    if (when >= 0)
        printw("(%d) %d", when, value);
    else
        printw("%d", value);
}

void Console::showIntAsHexProperty(int row, int col, std::string label, int value, int when)
{
    _showLabel(row, col, label);
    std::string hexi = int_to_hex(value, "");
    if (when >= 0)
        printw("(%d) %s", when, hexi.c_str());
    else
        printw("%s", hexi.c_str());
}

void Console::showBoolProperty(int row, int col, std::string label, bool value)
{
    _showLabel(row, col, label);
    if (value)
        printw("True");
    else
        printw("False");
}

void Console::showClockEdge(int row, int col, int clkState, int when)
{
    attrset(A_NORMAL);
    // mvprintw(row, col, "Clock (%d): ", when);
    mvaddstr(row, col, "Clock: ");
    attrset(A_BOLD);

    if (clkState == 0)
    {
        mvaddch(row, col + 8, '_'); // __/--
        mvaddch(row, col + 9, '/');
        mvaddch(row, col + 10, ACS_S1);
        p_clkState = clkState;
    }
    else if (clkState == 1)
    {
        mvaddch(row, col + 8, ACS_S1); // --\__
        mvaddch(row, col + 9, '\\');
        mvaddch(row, col + 10, '_');
        p_clkState = clkState;
    }
    else
    {
        if (p_clkState == 0)
        {
            mvaddch(row, col + 8, ACS_S1);
            mvaddch(row, col + 9, ACS_S1);
            mvaddch(row, col + 10, ACS_S1);
        }
        else
        {
            mvaddch(row, col + 8, '_');
            mvaddch(row, col + 9, '_');
            mvaddch(row, col + 10, '_');
        }
    }

    // printw(" (%d)", when);
}

void Console::showCPUState(int row, int col, std::string label, int value)
{
    _showLabel(row, col, label);
    switch (value)
    {
    case 0:
        printw("Reset");
        break;
    case 1:
        printw("Fetch");
        break;
    case 2:
        printw("Decode");
        break;
    case 3:
        printw("Execute");
        break;
    default:
        break;
    }
}

void Console::showVectorState(int row, int col, std::string label, int value)
{
    _showLabel(row, col, label);
    switch (value)
    {
    case 0:
        printw("Sync0");
        break;
    case 1:
        printw("Vector0");
        break;
    case 2:
        printw("Vector1");
        break;
    case 3:
        printw("Vector2");
        break;
    case 4:
        printw("Vector3");
        break;
    default:
        break;
    }
}

void Console::showALUOp(int row, int col, std::string label, int value)
{
    _showLabel(row, col, label);
    switch (value)
    {
    case 0b000000:
        printw("Add");
        break;
    case 0b000010:
        printw("Sub");
        break;
    case 0b001000:
        printw("Sll");
        break;
    case 0b010000:
        printw("Slt");
        break;
    case 0b011000:
        printw("Sltu");
        break;
    case 0b100000:
        printw("Xor");
        break;
    case 0b101000:
        printw("Srl");
        break;
    case 0b101010:
        printw("Sra");
        break;
    case 0b110000:
        printw("Or");
        break;
    case 0b111000:
        printw("And");
        break;
    default:
        break;
    }
}

void Console::showALUFlagsProperty(int row, int col, std::string label, int value)
{
    _showLabel(row, col, label);
    switch (value)
    {
    case 0b0000:
        printw("----");
        break;
    case 0b0001:
        printw("---Z");
        break;
    case 0b0010:
        printw("--C-");
        break;
    case 0b0011:
        printw("--CZ");
        break;
    case 0b0100:
        printw("-N--");
        break;
    case 0b0101:
        printw("-N-Z");
        break;
    case 0b0110:
        printw("-NC-");
        break;
    case 0b0111:
        printw("-NCZ");
        break;
    case 0b1000:
        printw("V---");
        break;
    case 0b1001:
        printw("V--Z");
        break;
    case 0b1010:
        printw("V-C-");
        break;
    case 0b1011:
        printw("V-CZ");
        break;
    case 0b1100:
        printw("VN--");
        break;
    case 0b1101:
        printw("VN-Z");
        break;
    case 0b1110:
        printw("VNC-");
        break;
    case 0b1111:
        printw("VNCZ");
        break;
    default:
        break;
    }
}

void Console::showRegFile(int row, int col, VlUnpacked<IData, 32> values)
{
    mvaddstr(row, col, "--- RegFile ---");
    row++;

    for (int i = 0; i < 32; i++)
    {
        move(row, col);
        attrset(A_NORMAL);
        if (i < 10)
            printw(" x%d: ", i);
        else
            printw("x%d: ", i);
        attrset(A_BOLD);
        printw("%s", int_to_hex(values[i], "").c_str());
        row++;
    }
}

// Show mem dump from A to B and ascii
void Console::showMemory(int row, int col, long int fromAddr, int memLen, VlUnpacked<IData, 1024> mem)
{
    // Addr           data          Ascii
    // 0x0000000a     0x01010101    ..ll
    // int row = 1;
    // int col = 70;

    mvaddstr(row, col, " ---------- Memory -------");
    row++;

    // Check if the fromAddr+memLen > memLen
    int toAddr = fromAddr + 32;
    if (toAddr > memLen)
    {
        toAddr = memLen;
    }

    for (int i = fromAddr; i < toAddr; i++)
    {
        move(row, col);

        attrset(A_NORMAL);
        printw("%s: ", int_to_hex(i, "0x").c_str());

        attrset(A_BOLD);
        std::string data = int_to_hex(mem[i], "");
        printw("%s  ", data.c_str());

        // Display text column
        std::string bye = {data[0], data[1]};
        int bt = hex_string_to_int(bye);
        if (bt >= 32 && bt <= 126)
            printw("%c", bt);
        else
            printw(".");

        bye = {data[2], data[3]};
        bt = hex_string_to_int(bye);
        if (bt >= 32 && bt <= 126)
            printw("%c", bt);
        else
            printw(".");

        bye = {data[4], data[5]};
        bt = hex_string_to_int(bye);
        if (bt >= 32 && bt <= 126)
            printw("%c", bt);
        else
            printw(".");

        bye = {data[6], data[7]};
        bt = hex_string_to_int(bye);
        if (bt >= 32 && bt <= 126)
            printw("%c", bt);
        else
            printw(".");

        row++;
    }
}

// --------------------------------------------------------------------
// Getters
// --------------------------------------------------------------------
std::string Console::getCmd(void)
{
    return lastCmd;
}

const std::string &Console::getArg1(void) { return arg1; }
const std::string &Console::getArg2(void) { return arg2; }
const std::string &Console::getArg3(void) { return arg3; }
const std::string &Console::getArg4(void) { return arg4; }
const std::string &Console::getArg5(void) { return arg5; }

long int Console::getArg1Int(void)
{
    return string_to_int(arg1);
}

long int Console::getArg2Int(void)
{
    return string_to_int(arg2);
}

bool Console::getArg1Bool(void)
{
    return string_to_bool(arg1);
}