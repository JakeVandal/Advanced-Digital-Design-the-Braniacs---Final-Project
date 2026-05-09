`timescale 1ns / 100ps
module ID_Check_testbench();
    reg clk;
    reg rst;
    reg btn;
    reg logout;
    reg [3:0] digit;
    wire [15:0] rom_value;
    wire matched_id, guest;
    wire [2:0] addr, internal_id;

    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end
    ID_ROM DUT_ROM (addr, clk, rom_value);
    // module ID_Check(digit, btn, logout, guest, rom_value, matched_id, addr, internal_id, clk, rst);
    ID_Check DUT_ID (digit, btn, logout, guest, rom_value, matched_id, addr, internal_id, clk, rst);

    initial begin
        rst = 1'b0; // reset the system
        btn = 1'b0; // button not pressed
        digit = 4'h0; // start with 0

        @(posedge clk);
        rst = 1'b1; // release reset

        // Test Case 1: Enter ID 1234 (matches ROM value at address 0)
        digit = 4'h8; // enter first digit
        @(posedge clk);
        btn = 1'b1; // press button to submit first digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h9; // enter second digit
        @(posedge clk);
        btn = 1'b1; // press button to submit second digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h8; // enter third digit
        @(posedge clk);
        btn = 1'b1; // press button to submit third digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h7; // enter fourth digit
        @(posedge clk);
        btn = 1'b1; // press button to submit fourth digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        logout <= 1'b1; // signal logout to reset for next test case
        @(posedge clk);
        logout <= 1'b0; // release logout
        @(posedge clk);
            

        // Test Case 2: Enter ID 5678 (does not match any ROM value)
        digit = 4'h5; // enter first digit
        @(posedge clk);
        btn = 1'b1; // press button to submit first digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h6; // enter second digit
        @(posedge clk);
        btn = 1'b1; // press button to submit second digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h7; // enter third digit
        @(posedge clk);
        btn = 1'b1; // press button to submit third digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h8; // enter fourth digit
        @(posedge clk);
        btn = 1'b1; // press button to submit fourth digit
        @(posedge clk);
        btn = 1'b0; // release button   

    end

endmodule