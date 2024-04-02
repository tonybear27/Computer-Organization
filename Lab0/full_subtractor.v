`timescale 1ns / 1ps

module Full_Subtractor(
    In_A, In_B, Borrow_in, Difference, Borrow_out
    );
    input In_A, In_B, Borrow_in;
    output Difference, Borrow_out;
    wire Diff_from_HSUB1, Borrow_from_HSUB1;

    // Implement full subtractor circuit using half subtractor
    Half_Subtractor HSUB1 (
        .In_A(In_A),
        .In_B(In_B),
        .Difference(Diff_from_HSUB1),
        .Borrow_out(Borrow_from_HSUB1)
    );

    // XOR the output of the half subtractor with Borrow_in to get the final Difference
    assign Difference = Diff_from_HSUB1 ^ Borrow_in;

    // Implement Borrow_out logic using AND gate
    assign Borrow_out = (Borrow_from_HSUB1 & ~Borrow_in) | (~Diff_from_HSUB1 & Borrow_in);
    
endmodule
