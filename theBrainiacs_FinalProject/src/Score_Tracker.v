module Score_Tracker(score_req, player_id, score, ram_value, wren, player_id_out, score_out, personal_winner, global_winner, clk, rst);
    input score_req, clk, rst;
    input [2:0] player_id;
    input [7:0] score, ram_value;
    output reg [2:0] player_id_out;
    output reg [7:0] score_out;
    output reg personal_winner, global_winner, wren;

    reg [2:0] winning_player; // player with most points
    reg [7:0] global_winning_score; // highest score across all players9
    reg [7:0] ram_store_score; // score stored from RAM to be compared with current score
    // set a flag in reset == 1'b0 to inititalize the flag
    reg [3:0] State;
    parameter RAMINIT = 0, WAIT = 1, FETCH = 2, CYC1 = 3, CYC2 = 4, CATCH = 5, COMP = 6, WRITE = 7, GLOBAL = 8;

    always @(posedge clk) begin
        if(rst == 1'b0) begin
            player_id_out <= 3'b000;
            score_out <= 8'b00000000;
            winning_player <= 3'b000;
            global_winning_score <= 8'b00000000;
            personal_winner <= 1'b0;
            global_winner <= 1'b0;
            wren <= 1'b1;
            State <= RAMINIT;
        end
        else begin
            case(State)

                RAMINIT: begin
                    if(player_id_out != 3'b111) begin
                        player_id_out <= player_id_out + 1;
                        State <= RAMINIT;
                    end
                    else begin
                        player_id_out <= 3'b000;
                        State <= WAIT;
                        wren <= 1'b0;
                    end
                end

                WAIT: begin
                    if(score_req == 1'b1) begin
                        player_id_out <= player_id;
                        State <= FETCH;
                    end
                    else begin
                        State <= WAIT;
                    end
                end

                FETCH: begin
                    State <= CYC1;
                end

                CYC1: begin
                    State <= CYC2;
                end

                CYC2: begin
                    State <= CATCH;
                end

                CATCH: begin
                    ram_store_score <= ram_value;
                    State <= COMP;
                end 

                COMP: begin 
                    if(score > ram_store_score) begin
                        personal_winner <= 1'b1;
                    end
                    else begin
                        personal_winner <= 1'b0;
                    end
                    State <= WRITE;
                end

                WRITE: begin
                    if(score > ram_store_score) begin
                        wren <= 1'b1;
                        score_out <= score;
                    end
                    else begin
                        wren <= 1'b0;
                        score_out <= ram_store_score;
                    end
                    State <= GLOBAL;
                end

                GLOBAL: begin
                    wren <= 1'b0;
                    if(score > global_winning_score) begin
                        global_winning_score <= score;
                        winning_player <= player_id;
                        global_winner <= 1'b1;
                    end
                    else begin
                        global_winner <= 1'b0;
                    end
                    State <= WAIT;
                end

            endcase
        end
    end
endmodule