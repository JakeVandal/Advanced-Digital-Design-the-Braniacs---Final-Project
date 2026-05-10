`timescale 1ns / 100ps
module Password_Check_testbench();
    reg [2:0] internal_id;
    reg [3:0] digit;    
    wire [23:0] rom_value; // password from password ROM
    reg btn, clk, logout_game_control, matched_id, guest, rst;
    wire [2:0] internal_id_out, addr;
    wire logout, logged_in, guest_pswd;

    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end
    // module Password_Check(digit, btn, logout_game_control, guest, matched_id, internal_id, rom_value, addr, logout, guest_pswd, internal_id_out, logged_in, clk, rst);
    Password_Check DUT(digit, btn, logout_game_control, guest, matched_id, internal_id, rom_value, addr, logout, guest_pswd, internal_id_out, logged_in, clk, rst);
    PASSWORD_ROM DUT_ROM(addr, clk, rom_value);
    initial begin
        rst = 1'b0; // reset the system
        btn = 1'b0; // button not pressed
        digit = 4'h0; // start with 0
        internal_id = 3'b000; // start with ID 0
        guest = 1'b0; // not a guest
        matched_id = 1'b1; // matched ID

        @(posedge clk);
        rst = 1'b1; // release reset

        // 7C91AE
        internal_id = 3'b000; // set internal ID to 0
        digit = 4'h7; // enter first digit
        @(posedge clk);
        btn = 1'b1; // press button to submit first digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'hC; // enter second digit
        @(posedge clk);
        btn = 1'b1; // press button to submit second digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h9; // enter third digit
        @(posedge clk);
        btn = 1'b1; // press button to submit third digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'h1; // enter fourth digit
        @(posedge clk);
        btn = 1'b1; // press button to submit fourth digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'hA; // enter fifth digit
        @(posedge clk);
        btn = 1'b1; // press button to submit fifth digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        digit = 4'hE; // enter sixth digit
        @(posedge clk);
        btn = 1'b1; // press button to submit sixth digit
        @(posedge clk);
        btn = 1'b0; // release button
        @(posedge clk);

        
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        
    end
endmodule