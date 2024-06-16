`timescale 1ns / 1ps
// 

/** [Reading] 4.7 p.372-375
 * Understand when and how to detect stalling caused by data hazards.
 * When read a reg right after it was load from memory,
 * it is impossible to solve the hazard just by forwarding.
 */

/* checkout FIGURE 4.59 to understand why a stall is needed */
/* checkout FIGURE 4.60 for how this unit should be connected */
module hazard_detection (
    input        branch,
    input        pc_src,
    input        ID_EX_mem_read,
    input  [4:0] ID_EX_rt,
    input  [4:0] IF_ID_rs,
    input  [4:0] IF_ID_rt,
    output  reg  pc_write,        // only update PC when this is set
    output  reg  IF_ID_write,     // only update IF/ID stage registers when this is set
    output  reg  IF_flush,        // for stall            
    output  reg  ID_flush
);

    /** [step 3] Stalling
     * 1. calculate stall by equation from textbook.
     * 2. Should pc be written when stall?
     * 3. Should IF/ID stage registers be updated when stall?
     */

    always @(*) begin

        /*** Initialize ***/
        pc_write <= 1'b1;
        IF_ID_write <= 1'b1;
        IF_flush <= 1'b0;
        ID_flush <= 1'b0;

        /*** Load Word ***/
        if (ID_EX_mem_read && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt) || (ID_EX_mem_read && branch))) begin
            pc_write <= 1'b0;
            IF_ID_write <= 1'b0;
            ID_flush <= 1'b1;
        end

        /*** Branch ***/
        if(pc_src) begin
            IF_flush <= 1'b1;
            ID_flush <= 1'b1;
        end
    end
    
endmodule
