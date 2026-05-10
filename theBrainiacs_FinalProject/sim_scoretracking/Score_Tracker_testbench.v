`timescale 1 ns / 100 ps
module Score_Tracker_testbench();
    reg score_req, clk, rst;
    reg [2:0] player_id;
    reg [7:0] score;
    wire [2:0] player_id_out;
    wire [7:0] score_out, ram_value;
    wire personal_winner, global_winner;
    wire wren;

    Score_Tracker ST(score_req, player_id, score, ram_value, wren, player_id_out, score_out, personal_winner, global_winner, clk, rst);
    SCORE_RAM RAM(player_id_out, clk, score_out, wren, ram_value);

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst = 1'b0;
        score_req = 1'b0;
        player_id = 3'b000;
        score = 8'h00;
        #25 rst = 1'b1;

        // wait for RAMINIT to finish (8 cycles)
        #160;
        @(posedge clk);

        // Test 1: Player 1, score=10, RAM=0 -> personal=1, global=1
        player_id = 3'b001; score = 8'd10;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 2: Player 1, score=5, RAM=10 -> personal=0, global=0
        @(posedge clk);
        player_id = 3'b001; score = 8'd5;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 3: Player 1, score=15, RAM=10 -> personal=1, global=1
        @(posedge clk);
        player_id = 3'b001; score = 8'd15;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 4: Player 1, score=15 again, RAM=15 -> personal=0, global=0 (not strictly greater)
        @(posedge clk);
        player_id = 3'b001; score = 8'd15;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 5: Player 1, score=20, RAM=15 -> personal=1, global=1
        @(posedge clk);
        player_id = 3'b001; score = 8'd20;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // --- Switch to Player 2 ---

        // Test 6: Player 2, score=8, RAM=0 -> personal=1, global=0 (p1 leads with 20)
        @(posedge clk);
        player_id = 3'b010; score = 8'd8;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 7: Player 2, score=5, RAM=8 -> personal=0, global=0
        @(posedge clk);
        player_id = 3'b010; score = 8'd5;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 8: Player 2, score=18, RAM=8 -> personal=1, global=0 (p1 still leads with 20)
        @(posedge clk);
        player_id = 3'b010; score = 8'd18;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 9: Player 2, score=18 again, RAM=18 -> personal=0, global=0 (not strictly greater)
        @(posedge clk);
        player_id = 3'b010; score = 8'd18;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        // Test 10: Player 2, score=25, RAM=18 -> personal=1, global=1 (beats p1's 20)
        @(posedge clk);
        player_id = 3'b010; score = 8'd25;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b1;
        @(posedge clk);
        @(posedge clk);
        score_req = 1'b0;
        #160;

        $stop;
    end
endmodule