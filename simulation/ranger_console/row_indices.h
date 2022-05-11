#pragma once
#include <stdio.h>

enum class RowPropId
{
    Timestep = 2,
    SimRunning,
    DelayTime,
    StepSize,
    ClockEdge,
    Ready,
    Reset,
    State,
    NxState,
    VecState,
    NxVecState,
    PC,
    PCPrior,
    PC_LD,
    PC_SRC,
    PC_SRC_OUT,
    MEM_WR,
    MEM_RD,
    PMMU_OUT,
    RSA_OUT,
    RSB_OUT,
    MDR,
    ADDR_SRC,
    RST_SRC,
    IR_LD,
    IR,
    IR_State,
    NxIR_State,
    WD_SRC,
    WD_SRC_OUT,
    A_SRC,
    A_MUX_OUT,
    B_SRC,
    B_MUX_OUT,
    IMM_EXT_OUT,
    ALU_OP,
    ALU_IMM_OUT,
    ALU_LD,
    ALU_OUT,
    ALU_FLAGS_LD,
    ALU_FLAGS,
};

// Handy template to allow conversion to "int"s, for example, +RowPropId::ClockEdge = 6
template <typename T>
constexpr auto operator+(T e) noexcept
    -> std::enable_if_t<std::is_enum<T>::value, std::underlying_type_t<T>>
{
    return static_cast<std::underlying_type_t<T>>(e);
}
