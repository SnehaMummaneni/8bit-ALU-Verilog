`timescale 1ns / 1ps

// ============================================================
//  Self-Checking Testbench - alu_8bit
//  Verifies all 16 operations + parity-based error detection
//  Author: Sneha Mummaneni
// ============================================================

module alu_8bit_tb;

    // DUT ports
    reg  [7:0] A, B;
    reg  [3:0] sel;
    wire [7:0] result;
    wire       carry_out, zero_flag, parity_out;

    // Parity error detection lives entirely in TB
    reg  parity_error;

    // Instantiate DUT - parity_error is NOT a DUT port
    alu_8bit uut (
        .A          (A),
        .B          (B),
        .sel        (sel),
        .result     (result),
        .carry_out  (carry_out),
        .zero_flag  (zero_flag),
        .parity_out (parity_out)
    );

    // Counters
    integer pass_count;
    integer fail_count;

    // Task: apply vector, check result + parity
    task apply_and_check;
        input [7:0]  ta, tb;
        input [3:0]  tsel;
        input [7:0]  expected_result;
        input        expected_carry;
        input [79:0] op_name;
        begin
            A   = ta;
            B   = tb;
            sel = tsel;
            #10;

            // TB computes expected parity and compares with DUT parity_out
            parity_error = (parity_out !== (^expected_result)) ? 1'b1 : 1'b0;

            if ((result      === expected_result) &&
                (carry_out   === expected_carry)  &&
                (parity_error === 1'b0)) begin
                $display("PASS | %-10s | A=%08b B=%08b | Result=%08b Carry=%b Parity=%b",
                          op_name, ta, tb, result, carry_out, parity_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %-10s | A=%08b B=%08b | Got=%08b Exp=%08b Carry=%b ExpC=%b ParityErr=%b",
                          op_name, ta, tb, result, expected_result,
                          carry_out, expected_carry, parity_error);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=============================================================");
        $display("   8-bit ALU - 16 Operations + Parity Error Detection");
        $display("=============================================================");

        // Arithmetic
        apply_and_check(8'h0A, 8'h05, 4'b0000, 8'h0F, 1'b0, "ADD       ");
        apply_and_check(8'hFF, 8'h01, 4'b0000, 8'h00, 1'b1, "ADD_CARRY ");
        apply_and_check(8'h0A, 8'h05, 4'b0001, 8'h05, 1'b0, "SUB       ");
        apply_and_check(8'h04, 8'h00, 4'b0010, 8'h05, 1'b0, "INC       ");
        apply_and_check(8'h04, 8'h00, 4'b0011, 8'h03, 1'b0, "DEC       ");

        // Logical
        apply_and_check(8'hF0, 8'h0F, 4'b0100, 8'h00, 1'b0, "AND       ");
        apply_and_check(8'hF0, 8'h0F, 4'b0101, 8'hFF, 1'b0, "OR        ");
        apply_and_check(8'hFF, 8'h0F, 4'b0110, 8'hF0, 1'b0, "XOR       ");
        apply_and_check(8'hF0, 8'h0F, 4'b0111, 8'hFF, 1'b0, "NAND      ");
        apply_and_check(8'hF0, 8'h0F, 4'b1000, 8'h00, 1'b0, "NOR       ");
        apply_and_check(8'hFF, 8'h0F, 4'b1001, 8'h0F, 1'b0, "XNOR      ");
        apply_and_check(8'hAA, 8'h00, 4'b1010, 8'h55, 1'b0, "NOT_A     ");

        // Shift / Rotate
        apply_and_check(8'h01, 8'h00, 4'b1011, 8'h02, 1'b0, "SHL       ");
        apply_and_check(8'h08, 8'h00, 4'b1100, 8'h04, 1'b0, "SHR       ");
        apply_and_check(8'h81, 8'h00, 4'b1101, 8'h03, 1'b0, "ROL       ");

        // Pass / Compare
        apply_and_check(8'hAB, 8'h00, 4'b1110, 8'hAB, 1'b0, "PASS_A    ");
        apply_and_check(8'h03, 8'h05, 4'b1111, 8'h01, 1'b0, "SLT_TRUE  ");
        apply_and_check(8'h05, 8'h03, 4'b1111, 8'h00, 1'b0, "SLT_FALSE ");

        // Parity error injection test
        $display("-------------------------------------------------------------");
        $display("  PARITY ERROR INJECTION TEST");
        A = 8'hFF; B = 8'h0F; sel = 4'b0110; #10; // XOR → 0xF0, parity=0
        parity_error = (parity_out !== 1'b1) ? 1'b1 : 1'b0; // inject wrong expected parity
        $display("  XOR result=%08b | parity_out(DUT)=%b | parity_error(injected)=%b",
                  result, parity_out, parity_error);
        if (parity_error === 1'b1)
            $display("  PASS | Error detection circuit fires correctly on parity mismatch");
        else
            $display("  FAIL | Error detection did not trigger as expected");

        $display("=============================================================");
        $display("  FINAL: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $display("=============================================================");
        $finish;
    end

endmodule