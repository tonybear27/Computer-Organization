`timescale 1ns / 1ps


/* checkout FIGURE C.5.10 (Bottom) */
/* [Prerequisite] complete bit_alu.v */
module msb_bit_alu (
    input        a,          // 1 bit, a
    input        b,          // 1 bit, b
    input        less,       // 1 bit, Less
    input        a_invert,   // 1 bit, Ainvert
    input        b_invert,   // 1 bit, Binvert
    input        carry_in,   // 1 bit, CarryIn
    input  [1:0] operation,  // 2 bit, Operation
    output reg   result,     // 1 bit, Result (Must it be a reg?)
    output       set,        // 1 bit, Set
    output       overflow    // 1 bit, Overflow
);

    /* Try to implement the most significant bit ALU by yourself! */
    wire ai, bi;
    assign ai = a ^ a_invert;
    assign bi = b ^ b_invert;
    
    wire sum, carry_out;
    assign sum = ai ^ bi ^ carry_in;
    assign carry_out = (ai & bi) | ((ai ^ bi) & carry_in);

    assign overflow = (operation == 2'b10) ? carry_in ^ carry_out: 0;
    assign set = (carry_in ^ carry_out) ? ~sum: sum;

    always @(*) begin  
        case (operation)  
            2'b00:   result <= ai & bi;  
            2'b01:   result <= ai | bi;  
            2'b10:   result <= sum;  
            2'b11:   result <= less;  
            default: result <= 0;
        endcase
    end
endmodule
