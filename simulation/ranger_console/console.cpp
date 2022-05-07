#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "console.h"
#include "commands.h"

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
    keypad(stdscr, true); // Enable non-blocking

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
            cmd = Command::Reset;

        if (keyBuffer == "ns")
            cmd = Command::NStep;

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

std::string Console::getCmd(void)
{
    return lastCmd;
}

void Console::clearCmdLine(void)
{
    move(LINES - 1, 2);
    clrtoeol();
}

void Console::showTermCaret(void)
{
    mvaddch(LINES - 1, 1, '>');
}

void Console::moveCaretToEndl(void)
{
    move(LINES - 1, col + 1);
}
void Console::showTimeStep(unsigned long int timeStep)
{
    move(2, 1);
    printw("                        ");
    move(2, 1);
    attrset(A_NORMAL);
    printw("timeStep: ");
    attrset(A_BOLD);
    printw("%d", timeStep);
}
