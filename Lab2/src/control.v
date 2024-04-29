`timescale 1ns / 1ps
// 110700045

/** [Reading] 4.4 p.318-321
 * "Designing the Main Control Unit"
 */
/** [Prerequisite] alu_control.v
 * This module is the Control unit in FIGURE 4.17
 * You can implement it by any style you want.
 */

/* checkout FIGURE 4.16/18 to understand each definition of control signals */
module control (
    input  [5:0] opcode,      // the opcode field of a instruction is [?:?]
    input   [5:0] funct,
    output       reg_dst,     // select register destination: rt(0), rd(1)
    output       alu_src,     // select 2nd operand of ALU: rt(0), sign-extended(1)
    output       mem_to_reg,  // select data write to register: ALU(0), memory(1)
    output       reg_write,   // enable write to register file
    output       mem_read,    // enable read form data memory
    output       mem_write,   // enable write to data memory
    output       branch,      // this is a branch instruction or not (work with alu.zero)
    output [1:0] alu_op,      // ALUOp passed to ALU Control unit
    output       lui_op,
    output       ori_op,     
    output       jump         // jump branch
);

    /* implement "combinational" logic satisfying requirements in FIGURE 4.18 */
    /* You can check the "Green Card" to get the opcode/funct for each instruction. */

    // R-Format: 0x0    : 00 0000
    // lw      : 0x23   : 10 0011
    // sw      : 0x2b   : 10 1011
    // beq     : 0x4    : 00 0100
    // j       : 0x2    : 00 0010
    // lui     : 0xf    : 00 1111
    // ori     : 0xd    : 00 1101

    wire re, lw, sw, beq, nop;
    assign re = ~opcode[0] & ~opcode[1] & ~opcode[2] & ~opcode[3] & ~opcode[4] & ~opcode[5];
    assign lw = opcode[0] & opcode[1] & ~opcode[2] & ~opcode[3] & ~opcode[4] & opcode[5];
    assign sw = opcode[0] & opcode[1] & ~opcode[2] & opcode[3] & ~opcode[4] & opcode[5];
    assign beq = ~opcode[0] & ~opcode[1] & opcode[2] & ~opcode[3] & ~opcode[4] & ~opcode[5];
    assign nop = (~|funct) & re;

    assign alu_op[0] = beq;
    assign alu_op[1] = re;


    assign reg_dst = re;
    assign alu_src = lw | sw;
    assign reg_write = (re & ~nop) | lw | lui_op | ori_op;
    assign mem_read = lw;
    assign mem_write = sw;
    assign mem_to_reg = lw;
    assign branch = beq;

    assign lui_op = opcode[0] & opcode[1] & opcode[2] & opcode[3] & ~opcode[4] & ~opcode[5];
    assign ori_op = opcode[0] & ~opcode[1] & opcode[2] & opcode[3] & ~opcode[4] & ~opcode[5];
    assign jump = ~opcode[0] & opcode[1] & ~opcode[2] & ~opcode[3] & ~opcode[4] & ~opcode[5];


endmodule
