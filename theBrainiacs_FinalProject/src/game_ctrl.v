//Manav Patel
//ECE:6370
// Memory Game Controller with Difficulty Selection, Internal LFSR Random Numbers, and Score Tracking

module game_ctrl(
    input clk,
    input rst,
    input pass_good,
    input btn1,     // Already shaped by ButtonShaper
    input btn2,     // Already shaped by ButtonShaper
    input btn3,     // Already shaped by ButtonShaper
    input time_out,
    input [3:0] sw,
    
    output reg load_out,
    output reg start_out,
    output reg timer_en,
    output reg timer_reconfig,
    output reg [7:0] timer_val,
    output reg logout,
    output reg [2:0] diff_led,
    output reg [15:0] disp_data,
    output reg [7:0] score
);

    parameter IDLE = 0,
              SEL_DIFF = 1,
              SHOW = 2,
              WAIT_INPUT = 3,
              CHECK = 4,
              UPDATE = 5,
              ROUND_END = 6,
              GAME_END = 7;
    
    reg [2:0] state;
    reg [1:0] difficulty;
    reg [3:0] stored_nums [0:3];
    reg [1:0] num_req;
    reg [1:0] guess_idx;
    reg [3:0] current_guess;
    reg [7:0] score_reg;
    reg [2:0] show_pulse_cnt;
    wire one_sec_show;
    reg show_timer_en;
    
    // Internal LFSR registers
    reg [15:0] lfsr;
    wire feedback;
    reg lfsr_enable;
    
    // LFSR feedback polynomial
    assign feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    // Show timer instance
    onesecTimer_show show_timer(show_timer_en, one_sec_show, clk, rst);
    
    // Internal LFSR - runs only when enabled
    always @(posedge clk) begin
        if (rst == 1'b0) begin
            lfsr <= 16'h3E42;  // Seed value for testing
        end
        else if (lfsr_enable == 1'b1) begin
            lfsr[0] <= feedback;
            lfsr[1] <= lfsr[0];
            lfsr[2] <= lfsr[1] ^ feedback;
            lfsr[3] <= lfsr[2] ^ feedback;
            lfsr[4] <= lfsr[3];
            lfsr[5] <= lfsr[4] ^ feedback;
            lfsr[6] <= lfsr[5];
            lfsr[7] <= lfsr[6];
            lfsr[8] <= lfsr[7];
            lfsr[9] <= lfsr[8];
            lfsr[10] <= lfsr[9];
            lfsr[11] <= lfsr[10];
            lfsr[12] <= lfsr[11];
            lfsr[13] <= lfsr[12];
            lfsr[14] <= lfsr[13];
            lfsr[15] <= lfsr[14];
        end
    end
    
    always @(posedge clk) begin
        if (rst == 1'b0) begin
            load_out <= 1'b0;
            start_out <= 1'b0;
            timer_en <= 1'b0;
            timer_reconfig <= 1'b0;
            timer_val <= 8'h30;
            logout <= 1'b0;
            diff_led <= 3'b001;
            disp_data <= 16'h0000;
            score <= 8'd0;
            state <= IDLE;
            difficulty <= 2'd0;
            num_req <= 2'd2;
            guess_idx <= 2'd0;
            current_guess <= 4'd0;
            score_reg <= 8'd0;
            show_pulse_cnt <= 3'd0;
            show_timer_en <= 1'b0;
            lfsr_enable <= 1'b0;
            stored_nums[0] <= 4'd0;
            stored_nums[1] <= 4'd0;
            stored_nums[2] <= 4'd0;
            stored_nums[3] <= 4'd0;
        end
        else begin
            load_out <= 1'b0;
            start_out <= 1'b0;
            timer_reconfig <= 1'b0;
            logout <= 1'b0;
            
            case (state)
                IDLE: begin
                    timer_en <= 1'b0;
                    score_reg <= 8'd0;
                    score <= 8'd0;
                    guess_idx <= 2'd0;
                    show_pulse_cnt <= 3'd0;
                    show_timer_en <= 1'b0;
                    disp_data <= 16'h0000;
                    lfsr_enable <= 1'b0;  // LFSR off in IDLE
                    
                    if (pass_good == 1'b1) begin
                        state <= SEL_DIFF;
                        difficulty <= 2'd0;
                        diff_led <= 3'b001;
                        num_req <= 2'd2;
                        timer_val <= 8'h30;
                        lfsr_enable <= 1'b1;  // Start LFSR when password is good
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                
                SEL_DIFF: begin
                    timer_en <= 1'b0;
                    disp_data <= 16'h0000;
                    
                    if (btn3 == 1'b1) begin
                        if (difficulty == 2'd0) begin
                            difficulty <= 2'd1;
                            diff_led <= 3'b010;
                            num_req <= 2'd3;
                            timer_val <= 8'h40;
                        end
                        else if (difficulty == 2'd1) begin
                            difficulty <= 2'd2;
                            diff_led <= 3'b100;
                            num_req <= 2'd4;
                            timer_val <= 8'h50;
                        end
                        else begin
                            difficulty <= 2'd0;
                            diff_led <= 3'b001;
                            num_req <= 2'd2;
                            timer_val <= 8'h30;
                        end
                        state <= SEL_DIFF;
                    end
                    else if (btn2 == 1'b1) begin
                        // FOR TESTING: Hardcode disp_data to see if displays work
                        // Comment this out and uncomment the LFSR capture after testing
                        
                        // TEST: Show 1,2,3,4 on displays
                        //disp_data <= 16'h1234;
                        //stored_nums[0] <= 4'h1;
                        //stored_nums[1] <= 4'h2;
                        //stored_nums[2] <= 4'h3;
                        //stored_nums[3] <= 4'h4;
                        
                         //UNCOMMENT THIS AFTER TESTING DISPLAYS
                        if (difficulty == 2'd0) begin
                            stored_nums[0] <= lfsr[7:4];
                            stored_nums[1] <= lfsr[3:0];
                            disp_data <= {lfsr[7:4], lfsr[3:0], 8'h00};
                        end
                        else if (difficulty == 2'd1) begin
                            stored_nums[0] <= lfsr[11:8];
                            stored_nums[1] <= lfsr[7:4];
                            stored_nums[2] <= lfsr[3:0];
                            disp_data <= {lfsr[11:8], lfsr[7:4], lfsr[3:0], 4'h0};
                        end
                        else begin
                            stored_nums[0] <= lfsr[15:12];
                            stored_nums[1] <= lfsr[11:8];
                            stored_nums[2] <= lfsr[7:4];
                            stored_nums[3] <= lfsr[3:0];
                            disp_data <= {lfsr[15:12], lfsr[11:8], lfsr[7:4], lfsr[3:0]};
                        end
                        
                        
                        timer_reconfig <= 1'b1;
                        show_pulse_cnt <= 3'd0;
                        show_timer_en <= 1'b1;
                        state <= SHOW;
                    end
                    else begin
                        state <= SEL_DIFF;
                    end
                end
                
                SHOW: begin
                    // Keep displaying numbers
                    
                    if (one_sec_show == 1'b1) begin
                        if (show_pulse_cnt == 3'd4) begin
                            show_timer_en <= 1'b0;
                            timer_en <= 1'b1;     // Start timer after 5 seconds
                            state <= WAIT_INPUT;
                            guess_idx <= 2'd0;
                            disp_data <= 16'h0000;  // Clear display
                        end
                        else begin
                            show_pulse_cnt <= show_pulse_cnt + 1;
                            state <= SHOW;
                        end
                    end
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;
                        timer_en <= 1'b0;
                        show_timer_en <= 1'b0;
                        state <= IDLE;
                    end
                    else begin
                        state <= SHOW;
                    end
                end
                
                WAIT_INPUT: begin
                    timer_en <= 1'b1;
                    
                    if (time_out == 1'b1) begin
                        timer_en <= 1'b0;
                        state <= GAME_END;
                    end
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;
                        timer_en <= 1'b0;
                        state <= IDLE;
                    end
                    else if (btn1 == 1'b1) begin
                        current_guess <= sw;
                        state <= CHECK;
                    end
                    else begin
                        state <= WAIT_INPUT;
                    end
                end
                
                CHECK: begin
                    timer_en <= 1'b1;
                    load_out <= 1'b1;
                    
                    if (current_guess == stored_nums[guess_idx]) begin
                        state <= UPDATE;
                    end
                    else begin
                        timer_en <= 1'b0;
                        state <= GAME_END;
                    end
                end
                
                UPDATE: begin
                    timer_en <= 1'b1;
                    
                    if (guess_idx + 1 == num_req) begin
                        score_reg <= score_reg + 1;
                        score <= score_reg + 1;
                        state <= ROUND_END;
                    end
                    else begin
                        guess_idx <= guess_idx + 1;
                        state <= WAIT_INPUT;
                    end
                end
                
                ROUND_END: begin
                    timer_en <= 1'b0;
                    
                    if (btn2 == 1'b1) begin
                        if (difficulty == 2'd0) begin
                            stored_nums[0] <= lfsr[7:4];
                            stored_nums[1] <= lfsr[3:0];
                            disp_data <= {lfsr[7:4], lfsr[3:0], 8'h00};
                        end
                        else if (difficulty == 2'd1) begin
                            stored_nums[0] <= lfsr[11:8];
                            stored_nums[1] <= lfsr[7:4];
                            stored_nums[2] <= lfsr[3:0];
                            disp_data <= {lfsr[11:8], lfsr[7:4], lfsr[3:0], 4'h0};
                        end
                        else begin
                            stored_nums[0] <= lfsr[15:12];
                            stored_nums[1] <= lfsr[11:8];
                            stored_nums[2] <= lfsr[7:4];
                            stored_nums[3] <= lfsr[3:0];
                            disp_data <= {lfsr[15:12], lfsr[11:8], lfsr[7:4], lfsr[3:0]};
                        end
                        
                        timer_reconfig <= 1'b1;
                        show_pulse_cnt <= 3'd0;
                        show_timer_en <= 1'b1;
                        state <= SHOW;
                    end
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        state <= ROUND_END;
                    end
                end
                
                GAME_END: begin
                    timer_en <= 1'b0;
                    
                    if (btn2 == 1'b1) begin
                        score_reg <= 8'd0;
                        score <= 8'd0;
                        guess_idx <= 2'd0;
                        state <= SEL_DIFF;
                    end
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        state <= GAME_END;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
