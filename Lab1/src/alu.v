`timescale 1ns / 1ps
//

/* checkout FIGURE C.5.12 */
/** [Prerequisite] complete bit_alu.v & msb_alu.v
 * We recommend you to design a 32-bit ALU with 1-bit ALU.
 * However, you can still implement ALU with more advanced feature in Verilog.
 * Feel free to code as long as the I/O ports remain the same shape.
 */
module alu (
    input  [31:0] a,        // 32 bits, source 1 (A)
    input  [31:0] b,        // 32 bits, source 2 (B)
    input  [ 3:0] ALU_ctl,  // 4 bits, ALU control input
    output [31:0] result,   // 32 bits, result
    output        zero,     // 1 bit, set to 1 when the output is 0
    output        overflow  // 1 bit, overflow
);
    /* [step 1] instantiate multiple modules */
    /**
     * First, we need wires to expose the I/O of 32 1-bit ALUs.
     * You might wonder if we can declare `operation` by `wire [31:0][1:0]` for better readability.
     * No, that is a feature call "packed array" in "System Verilog" but we are using "Verilog" instead.
     * System Verilog and Verilog are similar to C++ and C by their relationship.
     */
    wire [31:0] less = 0;
    wire [31:0] carry_out, carry_in;
    wire [31:0] res;
    reg  [1:0] operation;  // flatten vector
    wire a_invert, b_invert; //inverter
    wire        set;  // set of most significant bit
    

    assign result = (ALU_ctl == 4'b1100) ? ~res : res;


    /**
     * Second, we instantiate the less significant 31 1-bit ALUs
     * How are these modules wried?
     */
    genvar k;
    generate 
        for(k = 0; k < 31; k = k + 1) begin : _
            bit_alu LSBs (
                .a(a[k]),
                .b        (b[k]),
                .less     (k == 0 ? set: less[k]),
                .a_invert (a_invert),
                .b_invert (b_invert),
                .carry_in (carry_in[k]),
                .operation(operation[1:0]),
                .result   (res[k]),
                .carry_out(carry_out[k])
            );
      end
    endgenerate
    
    /* Third, we instantiate the most significant 1-bit ALU */
    msb_bit_alu msb (
        .a        (a[31]),
        .b        (b[31]),
        .less     (less[31]),
        .a_invert (a_invert),
        .b_invert (b_invert),
        .carry_in (carry_in[31]),
        .operation(operation[1:0]),
        .result   (res[31]),
        .set      (set),
        .overflow (overflow)
    );
    /** [step 2] wire these ALUs correctly
     * 1. `a` & `b` are already wired.
     * 2. About `less`, only the least significant bit should be used when SLT, so the other 31 bits ...?
     *    checkout: https://www.chipverify.com/verilog/verilog-concatenation
     * 3. `a_invert` should all connect to ?
     * 4. `b_invert` should all connect to ? (name it `b_negate` first!)
     * 5. What is the relationship between `carry_in[i]` & `carry_out[i-1]` ?
     * 6. `carry_in[0]` and `b_invert` appears to be the same when SUB... , right?
     * 7. `operation` should be wired to which 2 bits in `ALU_ctl` ?
     * 8. `result` is already wired.
     * 9. `set` should be wired to which `less` bit?
     * 10. `overflow` is already wired.
     * 11. You need another logic for `zero` output.
     */

    /*** step 2.5 ***/
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : ass
            assign carry_in[i] = carry_out[i-1];
        end
    endgenerate
    
    /*** step 2.6 ***/
    assign carry_in[0] = (ALU_ctl == 4'b0110 || ALU_ctl == 4'b0111) ? 1'b1 :1'b0;
    assign a_invert = 0;
    assign b_invert = (ALU_ctl == 4'b0110 || ALU_ctl == 4'b0111) ? 1'b1 :1'b0;

    
    /*** step 2.7 ***/
    always @(*) begin
        if (ALU_ctl == 4'b0000)
            operation = 2'b00;
        else if (ALU_ctl == 4'b0001)
            operation = 2'b01;
        else if (ALU_ctl == 4'b0010)
            operation = 2'b10;
        else if (ALU_ctl == 4'b0110)
            operation = 2'b10;
        else if (ALU_ctl == 4'b1100)
            operation = 2'b00;
        else if (ALU_ctl == 4'b0111)
            operation = 2'b11;
        else
            operation = 2'b00;
    end

    
   /*** step 2.11 ***/
   assign zero = ~|result;

endmodule
