#include <iostream>
#include <iomanip>

#include <ncurses.h>

#include "console.h"
#include "commands.h"
#include "utils.h"
#include "row_indices.h"

#define DEFAULT_COLOR 1
#define YELLOW_RED 2
#define YELLOW_DARK_GRAY 3
#define COLOR_DARK_GRAY 4
#define COLOR_LIGHT_GRAY 5
#define YELLOW_LIGHT_GRAY 6
#define GREEN_LIGHT_GRAY 7

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

    init_color(COLOR_DARK_GRAY, 128, 128, 128);
    init_color(COLOR_LIGHT_GRAY, 200, 200, 200);

    init_pair(YELLOW_RED, COLOR_YELLOW, COLOR_RED);
    init_pair(YELLOW_DARK_GRAY, COLOR_YELLOW, COLOR_DARK_GRAY);
    init_pair(YELLOW_LIGHT_GRAY, COLOR_YELLOW, COLOR_LIGHT_GRAY);
    init_pair(GREEN_LIGHT_GRAY, COLOR_GREEN, COLOR_LIGHT_GRAY);

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
    else if (ch == KEY_UP)
    {
        cmd = Command::MemScrollUp;
    }
    else if (ch == KEY_DOWN)
    {
        cmd = Command::MemScrollDwn;
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

        if (keyBuffer.rfind("rn", 0) == 0)
        {
            // Ex: rn fetch
            // or: rn decode
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields[1];
            cmd = Command::RunTo;
        }
        else if (keyBuffer.rfind("sg", 0) == 0)
        {
            // Ex: sg reset h
            cmd = Command::Signal;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields[1]; // reset, ...
            if (fields.size() > 2)
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
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "0"; // From
        }
        else if (keyBuffer.rfind("mm", 0) == 0)
        {
            // Modify memory address
            cmd = Command::MemModify;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "0"; // Address
            arg2 = fields.size() > 2 ? fields[2] : "0"; // value
        }
        else if (keyBuffer.rfind("ld", 0) == 0)
        {
            // Load a program from "rams" folder
            cmd = Command::LoadProg;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "ebreak"; // Program name "lw"
        }
        else if (keyBuffer.rfind("pc", 0) == 0)
        {
            // Set PC
            cmd = Command::SetPC;
            std::vector<std::string> fields = split_string(keyBuffer);
            arg1 = fields.size() > 1 ? fields[1] : "0x0";
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
void Console::show(Model &mdl)
{
    showULIntProperty(+RowPropId::Timestep, 1, "timeStep(ns)", mdl.timeStep_ns);
    showBoolProperty(+RowPropId::SimRunning, 1, "Sim running", mdl.simRunning);
    showIntProperty(+RowPropId::DelayTime, 1, "Delay time", mdl.timeStepDelayms);
    showIntProperty(+RowPropId::StepSize, 1, "Step size", mdl.stepSize);

    // Clock edges
    if (mdl.p_clk_i == 0 && mdl.top->clk_i == 1)
        showClockEdge(+RowPropId::ClockEdge, 1, 0, mdl.timeStep_ns);
    else if (mdl.p_clk_i == 1 && mdl.top->clk_i == 0)
        showClockEdge(+RowPropId::ClockEdge, 1, 1, mdl.timeStep_ns);
    else
        showClockEdge(+RowPropId::ClockEdge, 1, 2, mdl.timeStep_ns);

    showIntProperty(+RowPropId::Ready, 1, "Ready", mdl.cm->ready);
    showIntProperty(+RowPropId::Reset, 1, "Reset", mdl.top->reset_i);
    showCPUState(+RowPropId::State, 1, "State", mdl.cm->state);
    showCPUState(+RowPropId::NxState, 1, "Nxt State", mdl.cm->vector_state);
    showVectorState(+RowPropId::VecState, 1, "Vec State", mdl.cm->vector_state);
    showVectorState(+RowPropId::NxVecState, 1, "Nxt Vec-State", mdl.cm->next_vector_state);

    showIntProperty(+RowPropId::Ready, 1, "Ready", mdl.top->ready_o);
    showIntProperty(+RowPropId::Reset, 1, "Reset", mdl.top->reset_i);

    showCPUState(+RowPropId::State, 1, "State", mdl.cm->state);
    showCPUState(+RowPropId::NxState, 1, "Nxt State", mdl.cm->next_state);
    showVectorState(+RowPropId::VecState, 1, "Vec-State", mdl.cm->vector_state);
    showVectorState(+RowPropId::NxVecState, 1, "Nxt Vec-State", mdl.cm->next_vector_state);

    int pcWA = mdl.pc->data_o / 4;
    showIntAsHexProperty(+RowPropId::PC, 1, "PC", pcWA);
    pcWA = mdl.pc_prior->data_o / 4;
    showIntAsHexProperty(+RowPropId::PCPrior, 1, "PC-prior", pcWA);
    showIntProperty(+RowPropId::PC_LD, 1, "PC_ld", mdl.cm->pc_ld);
    showIntProperty(+RowPropId::PC_SRC, 1, "PC_src", mdl.cm->pc_src);
    showIntAsHexProperty(+RowPropId::PC_SRC_OUT, 1, "PC_src_out", mdl.risc->pc_src_out);

    showIntProperty(+RowPropId::MEM_WR, 1, "Mem_wr", mdl.cm->mem_wr);
    showIntProperty(+RowPropId::MEM_RD, 1, "Mem_rd", mdl.cm->mem_rd);
    showIntAsHexProperty(+RowPropId::PMMU_OUT, 1, "Pmmu_out", mdl.risc->pmmu_out);
    showIntAsHexProperty(+RowPropId::RSA_OUT, 1, "RsA", mdl.rsa->data_o);
    showIntAsHexProperty(+RowPropId::RSB_OUT, 1, "RsB", mdl.rsb->data_o);
    showIntAsHexProperty(+RowPropId::MDR, 1, "MDR", mdl.mdr->data_o);
    showIntProperty(+RowPropId::ADDR_SRC, 1, "Addr_src", mdl.cm->addr_src);
    showIntProperty(+RowPropId::RST_SRC, 1, "Rst_src", mdl.cm->rst_src);

    showIntProperty(+RowPropId::IR_LD, 1, "IR_ld", mdl.ir->ld_i);
    showIntAsHexProperty(+RowPropId::IR, 1, "IR", mdl.ir->data_o);
    showIRState(+RowPropId::IR_State, 1, "IR-State", mdl.cm->ir_state);
    showIRState(+RowPropId::NxIR_State, 1, "Nxt IR-State", mdl.cm->next_ir_state);

    showIntProperty(+RowPropId::WD_SRC, 1, "WD_src", mdl.wd_mux->select_i);
    showIntAsHexProperty(+RowPropId::WD_SRC_OUT, 1, "WD_Src_Out", mdl.wd_mux->data_o);

    showIntProperty(+RowPropId::A_SRC, 1, "A_src", mdl.a_mux->select_i);
    showIntAsHexProperty(+RowPropId::A_MUX_OUT, 1, "A_Mux_Out", mdl.a_mux->data_o);
    showIntProperty(+RowPropId::B_SRC, 1, "B_src", mdl.b_mux->select_i);
    showIntAsHexProperty(+RowPropId::B_MUX_OUT, 1, "B_Mux_Out", mdl.b_mux->data_o);

    showIntAsHexProperty(+RowPropId::IMM_EXT_OUT, 1, "IMM_Ext_Out", mdl.imm_ext->imm_o);

    showALUOp(+RowPropId::ALU_OP, 1, "ALUOp", mdl.alu->func_op_i);
    showIntAsHexProperty(+RowPropId::ALU_IMM_OUT, 1, "ALU_Imm_Out", mdl.alu->y_o);
    showIntProperty(+RowPropId::ALU_LD, 1, "ALU_ld", mdl.alu_out->ld_i);
    showIntAsHexProperty(+RowPropId::ALU_OUT, 1, "ALU_Out", mdl.alu_out->data_o);
    showIntProperty(+RowPropId::ALU_FLAGS_LD, 1, "ALU_flgs_ld", mdl.alu_flags->ld_i);
    showALUFlagsProperty(+RowPropId::ALU_FLAGS, 1, "ALU_Flags", mdl.alu_flags->data_o);

    showRegFile(2, 40, mdl.regFile->bank);

    showPCMarker(mdl);
    showPCPriorMarker(mdl);
}

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

void Console::showRegisterBin(int row, const std::string &header, int value)
{
    move(row, 1);
    attrset(A_NORMAL);
    printw("%s: ", header.c_str());
    attrset(A_BOLD);
    printw("%s", int_to_bin(value, "").c_str());
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

void Console::showIRState(int row, int col, std::string label, int value)
{
    _showLabel(row, col, label);
    switch (value)
    {
    case 0:
        printw("STStore");
        break;
    case 1:
        printw("STMemAcc");
        break;
    case 2:
        printw("STMemWrt");
        break;
    case 3:
        printw("STMemRrd");
        break;
    case 4:
        printw("ITLoad");
        break;
    case 5:
        printw("ITLDMemAcc");
        break;
    case 6:
        printw("ITLDMemMdr");
        break;
    case 7:
        printw("ITLDMemCmpl");
        break;
    case 8:
        printw("RType");
        break;
    case 9:
        printw("RTCmpl");
        break;
    case 10:
        printw("BType");
        break;
    case 11:
        printw("BTBranch");
        break;
    case 12:
        printw("BTCmpl");
        break;
    case 13:
        printw("ITALU");
        break;
    case 14:
        printw("ITALUCmpl");
        break;
    case 15:
        printw("JTJal");
        break;
    case 16:
        printw("JTJalRtr");
        break;
    case 17:
        printw("ITJalr");
        break;
    case 18:
        printw("ITJalrRtr");
        break;
    case 19:
        printw("UType");
        break;
    case 20:
        printw("UTCmpl");
        break;
    case 21:
        printw("UTypeAui");
        break;
    case 22:
        printw("UTAuiCmpl");
        break;
    case 23:
        printw("ITEbreak");
        break;
    case 24:
        printw("ITECall");
        break;
    case 25:
        printw("PreFetch");
        break;
    case 26:
        printw("IRUnknown");
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

    if (fromAddr < 0)
        fromAddr = 0;
    if (fromAddr > memLen)
        fromAddr = memLen - 1 - 32;

    // Check if the fromAddr+memLen > memLen
    int toAddr = fromAddr + 32;
    if (toAddr > memLen)
        toAddr = memLen;

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

void Console::showPCMarker(Model &mdl)
{
    // Calc row based on address using modulo
    //             0      v                              1023
    //             |- ---------------------------------- -|
    //
    //         |- ------- -|
    //         0           32
    int pc = mdl.pc->data_o / 4;
    if (pc >= mdl.fromAddr && pc < 1024)
    {
        mvaddstr(mdl.p_pcMarker, mdl.markerCol - 1, "    ");

        if (pc < mdl.fromAddr + 32)
        {
            int r = pc - mdl.fromAddr + mdl.rowOffset;
            attrset(COLOR_PAIR(YELLOW_LIGHT_GRAY) | A_BOLD);
            mvaddstr(r, mdl.markerCol, "PC>");
            mdl.p_pcMarker = r;
        }
    }
    else
        mvaddstr(mdl.p_pcMarker, mdl.markerCol - 1, "    ");
}

void Console::showPCPriorMarker(Model &mdl)
{
    int pc = mdl.pc_prior->data_o / 4;
    if (pc >= mdl.fromAddr && pc < 1024)
    {
        mvaddstr(mdl.p_pcpMarker, mdl.markerCol - 1, "    ");

        if (pc < mdl.fromAddr + 32)
        {
            int r = pc - mdl.fromAddr + mdl.rowOffset;
            attrset(COLOR_PAIR(GREEN_LIGHT_GRAY) | A_BOLD);
            mvaddstr(r, mdl.markerCol - 1, "PCP>");
            mdl.p_pcpMarker = r;
        }
    }
    else
        mvaddstr(mdl.p_pcpMarker, mdl.markerCol - 1, "    ");
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