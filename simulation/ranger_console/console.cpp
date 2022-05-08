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
        else if (keyBuffer.rfind("sim", 0) == 0)
        {
            cmd = Command::EnableSim;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "off";
        }
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
        } else {
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

int Console::getArg1Int(void)
{
    return string_to_int(arg1);
}

bool Console::getArg1Bool(void)
{
    return string_to_bool(arg1);
}