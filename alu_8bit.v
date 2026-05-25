`timescale 1ns / 1ps



module alu_8bit (
    input  [7:0] A,
    input  [7:0] B,
    input  [3:0] sel,           // 4-bit opcode → 16 operations
    output reg [7:0] result,
    output reg       carry_out,
    output reg       zero_flag,
    output reg       parity_out  // Even parity of result
);

    always @(*) begin
        carry_out = 1'b0;

        case (sel)
            // Arithmetic
            4'b0000: {carry_out, result} = A + B;           // ADD
            4'b0001: {carry_out, result} = A - B;           // SUB
            4'b0010: result = A + 8'b1;                     // INC A
            4'b0011: result = A - 8'b1;                     // DEC A

            // Logical
            4'b0100: result = A & B;                        // AND
            4'b0101: result = A | B;                        // OR
            4'b0110: result = A ^ B;                        // XOR
            4'b0111: result = ~(A & B);                     // NAND
            4'b1000: result = ~(A | B);                     // NOR
            4'b1001: result = ~(A ^ B);                     // XNOR
            4'b1010: result = ~A;                           // NOT A

            // Shift / Rotate
            4'b1011: result = A << 1;                       // SHL
            4'b1100: result = A >> 1;                       // SHR
            4'b1101: result = {A[6:0], A[7]};               // ROL

            // Pass / Compare
            4'b1110: result = A;                            // PASS A
            4'b1111: result = (A < B) ? 8'b1 : 8'b0;       // SLT

            default: result = 8'b0;
        endcase

        zero_flag  = (result == 8'b0) ? 1'b1 : 1'b0;
        parity_out = ^result;   // Even parity: XOR reduction
    end

endmodule