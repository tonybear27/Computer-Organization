`timescale 1ns / 1ps
// 

/** [Prerequisite] pipelined (Lab 3), forwarding, hazard_detection
 * This module is the pipelined MIPS processor "similar to" FIGURE 4.60 (control hazard is not solved).
 * You can implement it by any style you want, as long as it passes testbench.
 */

module pipelined #(
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
) (
    input clk,  // clock
    input rstn  // negative reset
);

    /** [step 0] Copy from Lab 3
     * You should modify your pipelined processor from Lab 3, so copy to here first.
     */

     /* Instruction Memory */
    wire [31:0] instr_mem_address, instr_mem_instr;
    instr_mem #(
        .BYTES(TEXT_BYTES),
        .START(TEXT_START)
    ) instr_mem (
        .address(instr_mem_address),
        .instr  (instr_mem_instr)
    );

    /* Register Rile */
    wire [4:0] reg_file_read_reg_1, reg_file_read_reg_2, reg_file_write_reg;
    wire reg_file_reg_write;
    wire [31:0] reg_file_write_data, reg_file_read_data_1, reg_file_read_data_2;
    reg_file reg_file (
        .clk        (~clk),                  // only write when negative edge
        .rstn       (rstn),
        .read_reg_1 (reg_file_read_reg_1),
        .read_reg_2 (reg_file_read_reg_2),
        .reg_write  (reg_file_reg_write),
        .write_reg  (reg_file_write_reg),
        .write_data (reg_file_write_data),
        .read_data_1(reg_file_read_data_1),
        .read_data_2(reg_file_read_data_2)
    );

    /* ALU */
    wire [31:0] alu_a, alu_b, alu_result;
    wire [3:0] alu_ALU_ctl;
    wire alu_zero, alu_overflow;
    alu alu (
        .a       (alu_a),
        .b       (alu_b),
        .ALU_ctl (alu_ALU_ctl),
        .result  (alu_result),
        .zero    (alu_zero),
        .overflow(alu_overflow)
    );

    /* Data Memory */
    wire data_mem_mem_read, data_mem_mem_write;
    wire [31:0] data_mem_address, data_mem_write_data, data_mem_read_data;
    data_mem #(
        .BYTES(DATA_BYTES),
        .START(DATA_START)
    ) data_mem (
        .clk       (~clk),                 // only write when negative edge
        .mem_read  (data_mem_mem_read),
        .mem_write (data_mem_mem_write),
        .address   (data_mem_address),
        .write_data(data_mem_write_data),
        .read_data (data_mem_read_data)
    );

    /* ALU Control */
    wire [1:0] alu_control_alu_op;
    wire [5:0] alu_control_funct;
    wire [3:0] alu_control_operation;
    alu_control alu_control (
        .alu_op   (alu_control_alu_op),
        .funct    (alu_control_funct),
        .operation(alu_control_operation)
    );

    /* (Main) Control */
    wire [5:0] control_opcode, control_funct;
    
    // Execution/address calculation stage control lines
    wire control_reg_dst, control_alu_src;
    wire [1:0] control_alu_op;
    
    // Memory access stage control lines
    wire control_branch, control_mem_read, control_mem_write;

    // Wire-back stage control lines
    wire control_reg_write, control_mem_to_reg;
    
    control control (
        .opcode    (control_opcode),
        .funct     (control_funct),
        .reg_dst   (control_reg_dst),
        .alu_src   (control_alu_src),
        .mem_to_reg(control_mem_to_reg),
        .reg_write (control_reg_write),
        .mem_read  (control_mem_read),
        .mem_write (control_mem_write),
        .branch    (control_branch),
        .alu_op    (control_alu_op)
    );

    /** [step 0.1] Instruction fetch (IF)
     * 1. We need a register to store PC (acts like pipeline register).
     * 2. Wire pc to instruction memory.
     * 3. Implement an adder to calculate PC+4. (combinational)
     *    Hint: use "+" operator.
     * 4. Update IF/ID pipeline registers, and reset them @(negedge rstn)
     *    a. fetched instruction
     *    b. PC+4
     *    Hint: What else should be done when reset?
     *    Hint: Update of PC can be handle later in MEM stage.
     */

    /*** Step 0.1.1 ***/
    reg [31:0] pc;  // DO NOT change this line
    
    /*** Step 0.1.2 ***/
    assign instr_mem_address = pc;

    /*** Step 0.1.3 ***/
    wire [31:0] pc_4 = pc + 4;

    /*** Step 0.1.4 ***/
    /*** 64 bits for ID/EX Register ***/
    reg [31:0] IF_ID_instr, IF_ID_pc_4;
    always @(posedge clk or negedge rstn) begin
        /*** Step 4.2 ***/
        if (~rstn) begin
            IF_ID_instr <= 0;
            IF_ID_pc_4  <= 0;
        end
        else begin
            /*** Step 5 Hazard **/
            if(IF_flush) begin
                IF_ID_instr <= 0;
                IF_ID_pc_4 <=0;
            end
            else begin
                if(IF_ID_write) begin
                    /*** Step 0.1.4.a ***/
                    IF_ID_instr <= instr_mem_instr;

                    /*** Step 0.1.4.b ***/
                    IF_ID_pc_4  <= pc_4;
                end
                else begin
                    /*** Step 5 Hazard ***/
                    IF_ID_instr <= IF_ID_instr;
                    IF_ID_pc_4 <= IF_ID_pc_4;
                end
            end
        end
    end

    /** [step 0.2] Instruction decode and register file read (ID)
     * From top to down in FIGURE 4.51: (instr. refers to the instruction from IF/ID)
     * 1. Generate control signals of the instr. (as Lab 2)
     * 2. Read desired registers (from register file) in the instr.
     * 3. Calculate sign-extended immediate from the instr.
     * 4. Update ID/EX pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB, MEM, EX)
     *    b. pc_4 (something from IF/ID)
     *    c. Data read from register file
     *    d. Sign-extended immediate
     *    e. Insrt[20:16] & Instr[15:11] (WB stage needs to know which reg to write)
     */

    /*** Step 0.2.1 ***/
    assign control_opcode = IF_ID_instr[31:26];
    assign control_funct = IF_ID_instr[5:0];

    /*** Step 0.2.2 ***/
    wire [4:0] reg_dest, IF_ID_reg_rs;

    /*** rd ***/
    assign reg_dest = IF_ID_instr[15:11]; 
    
    /*** rs ***/
    assign reg_file_read_reg_1 = IF_ID_instr[25:21];
    assign IF_ID_reg_rs = IF_ID_instr[25:21];

    /*** rt ***/
    wire [4:0] IF_ID_reg_rt;
    assign reg_file_read_reg_2 = IF_ID_instr[20:16];
    assign IF_ID_reg_rt = IF_ID_instr[20:16];
    
    /*** Step 0.2.3 ***/
    wire [31:0] signedExtented;
    assign signedExtented = { {16{IF_ID_instr[15]}}, IF_ID_instr[15:0] };

    /*** Step 0.2.4 ***/
    /*** WB register for ID/EX ***/
    reg ID_EX_WB_reg_write, ID_EX_WB_mem_to_reg;
    
    /*** M register for ID/EX ***/
    reg ID_EX_M_branch, ID_EX_M_mem_read, ID_EX_M_mem_write;
    
    /*** EX register for ID/EX ***/
    reg ID_EX_reg_dst, ID_EX_alu_src;
    reg [1:0] ID_EX_alu_op;

    /*** PC + 4 from IF/ID ***/
    reg [31:0] ID_EX_pc4;
    
    /*** Read data register  ***/
    reg [31:0] ID_EX_read_data1, ID_EX_read_data2;

    /*** Signed Extended registr ***/
    reg [31:0] ID_EX_Immed;

    /*** Registers for WB to write ***/
    reg [4:0] ID_EX_reg1, ID_EX_reg2;

    /*** Step 2.1 ***/
    reg [4:0] ID_EX_rs, ID_EX_rt;

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            ID_EX_WB_reg_write <= 0;
            ID_EX_WB_mem_to_reg <= 0;
            ID_EX_M_branch <= 0;
            ID_EX_M_mem_read <= 0;
            ID_EX_M_mem_write <= 0;
            ID_EX_reg_dst <= 0;
            ID_EX_alu_src <= 0;
            ID_EX_alu_op <= 0;
            ID_EX_pc4 <= 0;
            ID_EX_read_data1 <= 0;
            ID_EX_read_data2 <= 0;
            ID_EX_Immed <= 0;
            ID_EX_reg1 <= 0;
            ID_EX_reg2 <= 0;
            ID_EX_rs <= 0;
        end
        else begin
            /*** Step 0.2.4.a ***/
            if(ID_flush) begin
                ID_EX_WB_reg_write <= 0;
                ID_EX_WB_mem_to_reg <= 0;
                
                ID_EX_M_branch <= 0;
                ID_EX_M_mem_read <= 0;
                ID_EX_M_mem_write <= 0;

                ID_EX_reg_dst <= 0;
                ID_EX_alu_src <= 0;
                ID_EX_alu_op <= 0;
            end
            else begin
                ID_EX_WB_reg_write <= control_reg_write;
                ID_EX_WB_mem_to_reg <= control_mem_to_reg;
                
                ID_EX_M_branch <= control_branch;
                ID_EX_M_mem_read <= control_mem_read;
                ID_EX_M_mem_write <= control_mem_write;

                ID_EX_reg_dst <= control_reg_dst;
                ID_EX_alu_src <= control_alu_src;
                ID_EX_alu_op <= control_alu_op;    
            end
            

            /*** Step 0.2.4.b ***/
            ID_EX_pc4 <= IF_ID_pc_4;

            /*** Step 0.2.4.c ***/
            ID_EX_read_data1 <= reg_file_read_data_1;
            ID_EX_read_data2 <= reg_file_read_data_2;

            /*** Step 0.2.4.d ***/
            ID_EX_Immed <= signedExtented;

            /*** Step 0.2.4.e ***/
            ID_EX_reg1 <= reg_file_read_reg_2;
            ID_EX_reg2 <= reg_dest;

            /*** Step 2.1 ***/
            ID_EX_rs <= IF_ID_reg_rs;
            ID_EX_rt <= IF_ID_reg_rt;
        end
    end

    /** [step 0.3] Execute or address calculation (EX)
     * From top to down in FIGURE 4.51
     * 1. Calculate branch target address from sign-extended immediate.
     * 2. Select correct operands of ALU like in Lab 2.
     * 3. Wire control signals to ALU control & ALU like in Lab 2.
     * 4. Select correct register to write.
     * 5. Update EX/MEM pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB, MEM)
     *    b. Branch target address
     *    c. ??? (What information dose MEM stage need to determine whether to branch?)
     *    d. ALU result
     *    e. ??? (What information does MEM stage need when executing Store?)
     *    f. ??? (WB stage needs to know which reg to write)
     */

    /*** Step 0.3.1 ***/
    wire [31:0] target;
    assign target = ID_EX_pc4 + (ID_EX_Immed << 2);

    /*** Step 0.3.3 ***/
    assign alu_control_alu_op = ID_EX_alu_op;
    assign alu_control_funct = ID_EX_Immed[5:0];
    assign alu_ALU_ctl = alu_control_operation;

    /*** Step 0.3.4 ***/
    wire [4:0] reg_to_write;
    assign reg_to_write = ID_EX_reg_dst ? ID_EX_reg2: ID_EX_reg1;

    /*** Step 0.3.5 ***/
    /*** WB registers for EX/MEM ***/
    reg EX_MEM_WB_reg_write, EX_MEM_WB_mem_to_reg;
    
    /*** M registers for EX/MEM ***/
    reg EX_MEM_M_branch, EX_MEM_M_mem_read, EX_MEM_M_mem_write;

    reg [31:0] EX_MEM_branch, EX_MEM_alu_result, EX_MEM_read_data;
    reg [4:0] EX_MEM_write_data;
    reg EX_MEM_alu_zero;

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            EX_MEM_WB_reg_write <= 0;
            EX_MEM_WB_mem_to_reg <= 0; 
            EX_MEM_M_branch <= 0; 
            EX_MEM_M_mem_read <= 0; 
            EX_MEM_M_mem_write <= 0;
            EX_MEM_branch <= 0;
            EX_MEM_alu_result <= 0;
            EX_MEM_alu_zero <= 0; 
            EX_MEM_read_data <= 0; 
            EX_MEM_write_data <= 0;
        end
        else begin
            /*** Step 0.3.5.a ***/
            EX_MEM_WB_reg_write <= ID_EX_WB_reg_write;
            EX_MEM_WB_mem_to_reg <= ID_EX_WB_mem_to_reg;

            EX_MEM_M_branch <= ID_EX_M_branch; 
            EX_MEM_M_mem_read <= ID_EX_M_mem_read;
            EX_MEM_M_mem_write <= ID_EX_M_mem_write;

            /*** Step 0.3.5.b ***/
            EX_MEM_branch <= target;

            /*** Step 0.3.5.c ***/
            EX_MEM_alu_zero <= alu_zero;

            /*** Step 0.3.5.d ***/
            EX_MEM_alu_result <= alu_result;

            /*** Step 0.3.5.e ***/
            EX_MEM_read_data <= ID_EX_read_data2;

            /*** Step 0.3.5.f ***/
            EX_MEM_write_data <= reg_to_write;
        end
    end

    /** [step 0.4] Memory access (MEM)
     * From top to down in FIGURE 4.51
     * 1. Decide whether to branch or not.
     * 2. Wire address & data to write
     * 3. Wire control signal of read/write
     * 4. Update MEM/WB pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB)
     *    b. ???
     *    c. ???
     *    d. ???
     * 5. Update PC.
     */

    /*** Step 0.4.1 ***/
    wire targetAddr;
    assign targetAddr = EX_MEM_M_branch & EX_MEM_alu_zero;
    
    /*** Step 0.4.2 ***/
    assign data_mem_address = EX_MEM_alu_result;
    assign data_mem_write_data = EX_MEM_read_data;

    /*** Step 0.4.3 ***/
    assign data_mem_mem_write = EX_MEM_M_mem_write;
    assign data_mem_mem_read = EX_MEM_M_mem_read;

    /*** Step 0.4.4 ***/
    /*** WB register for MEM/WB ***/
    reg MEM_WB_WB_reg_write, MEM_WB_WB_mem_to_reg;

    reg [31:0] MEM_WB_alu_result, MEM_WB_read_data;
    reg [4:0] MEM_WB_write_data;

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            MEM_WB_WB_reg_write <= 0;
            MEM_WB_WB_mem_to_reg <= 0;
            MEM_WB_read_data <= 0;
            MEM_WB_alu_result <= 0;
            MEM_WB_write_data <= 0;
        end
        else begin
            /*** Step 0.4.4.a ***/
            MEM_WB_WB_reg_write <= EX_MEM_WB_reg_write;
            MEM_WB_WB_mem_to_reg <= EX_MEM_WB_mem_to_reg;

            /*** Step 0.4.4.b ***/
            MEM_WB_read_data <= data_mem_read_data;

            /*** Step 0.4.4.c ***/
            MEM_WB_alu_result <= EX_MEM_alu_result;

            /*** Step 0.4.4.d ***/
            MEM_WB_write_data <= EX_MEM_write_data;
        end
    end

    /*** Step 0.4.5 ***/
    always @(posedge clk or negedge rstn)
        if (~rstn) begin
            pc <= 32'h00400000;
        end
        else begin
            if(pc_write) 
                pc <= targetAddr? EX_MEM_branch: pc_4;  
            else
                pc <= pc;
        end

    /** [step 0.5] Write-back (WB)
     * From top to down in FIGURE 4.51
     * 1. Wire RegWrite of register file.
     * 2. Select the data to write into register file.
     * 3. Select which register to write.
     */

    /*** Step 0.5.1 ***/
    assign reg_file_reg_write = MEM_WB_WB_reg_write;

    /*** Step 0.5.2 ***/
    assign reg_file_write_data = MEM_WB_WB_mem_to_reg ? MEM_WB_read_data: MEM_WB_alu_result; 

    /*** Step 0.5.3 ***/
    assign reg_file_write_reg = MEM_WB_write_data;


    /** [step 2] Connect Forwarding unit
     * 1. add `ID_EX_rs` into ID/EX stage registers
     * 2. Use a mux to select correct ALU operands according to forward_A/B
     *    Hint don't forget that alu_b might be sign-extended immediate!
     */
    wire [1:0] forward_A, forward_B;
    forwarding forwarding (
        .ID_EX_rs        (ID_EX_rs),
        .ID_EX_rt        (ID_EX_rt),
        .EX_MEM_reg_write(EX_MEM_WB_reg_write),
        .EX_MEM_rd       (EX_MEM_write_data),
        .MEM_WB_reg_write(MEM_WB_WB_reg_write),
        .MEM_WB_rd       (MEM_WB_write_data),
        .forward_A       (forward_A),
        .forward_B       (forward_B)
    );

    /*** Step 2.2 ***/
    assign alu_a = forward_A == 2'b00 ? ID_EX_read_data1: (forward_A == 2'b01 ? reg_file_write_data: EX_MEM_alu_result);  // forward 1st operand
    assign alu_b = forward_B == 2'b00 ? (ID_EX_alu_src ? ID_EX_Immed: ID_EX_read_data2): (forward_B == 2'b01 ? reg_file_write_data: EX_MEM_alu_result);  // forward 2nd operand

    /** [step 4] Connect Hazard Detection unit
     * 1. use `pc_write` when updating PC
     * 2. use `IF_ID_write` when updating IF/ID stage registers
     * 3. use `stall` when updating ID/EX stage registers
     */
    wire pc_write, IF_ID_write, IF_flush, ID_flush;
    hazard_detection hazard_detection (
        .branch        (control_branch),
        .pc_src        (targetAddr),
        .ID_EX_mem_read(ID_EX_M_mem_read),
        .ID_EX_rt      (ID_EX_reg1),
        .IF_ID_rs      (IF_ID_reg_rs),
        .IF_ID_rt      (IF_ID_reg_rt),
        .pc_write      (pc_write),            // implicitly declared
        .IF_ID_write   (IF_ID_write),         // implicitly declared
        .IF_flush      (IF_flush),
        .ID_flush      (ID_flush)
    );

    /** [step 5] Control Hazard
     * This is the most difficult part since the textbook does not provide enough information.
     * By reading p.377-379 "Reducing the Delay of Branches",
     * we can disassemble this into the following steps:
     * 1. Move branch target address calculation & taken or not from EX to ID
     * 2. Move branch decision from MEM to ID
     * 3. Add forwarding for registers used in branch decision from EX/MEM
     * 4. Add stalling:
          branch read registers right after an ALU instruction writes it -> 1 stall
          branch read registers right after a load instruction writes it -> 2 stalls
     */

endmodule  // pipelined
