//Manav Patel
//ECE:6370
// Memory Game Controller with Difficulty Selection, LFSR Random Numbers, and Score Tracking
// Score increases by 1 ONLY when ALL numbers in the sequence are guessed correctly in order
// Display shows numbers LEFT TO RIGHT (Sevenseg_4, Sevenseg_3, Sevenseg_2, Sevenseg_1)
// Guessing order is LEFT TO RIGHT

module game_ctrl(  // Main game controller module
    input clk,      // Clock signal
    input rst,      // Reset signal (active low)
    input pass_good, // Password verification complete signal from password module
    input btn1,     // Button 1 - load guess
    input btn2,     // Button 2 - start game
    input btn3,     // Button 3 - cycle difficulty / logout
    input time_out, // Timer reached zero signal from digit timer
    input [15:0] lfsr_q, // 16-bit random number from LFSR (always running)
    input [3:0] sw, // 4-bit switches for user input guesses
    
    output reg load_out,    // Output to pass btn1 through to other modules
    output reg start_out,   // Output to pass btn2 through to other modules
    output reg timer_en,    // Enable signal for digit timer
    output reg timer_reconfig, // Reset/reconfigure signal for digit timer
    output reg [7:0] timer_val, // BCD value to load into timer (30,40,50)
    output reg logout,      // Signal to password module to require re-authentication
    output reg [2:0] diff_led, // 3 LEDs to show current difficulty (001,010,100)
    output reg [15:0] disp_data, // 4-digit BCD data for 7-segment displays (4 bits per digit)
    output reg [3:0] disp_en, // Enable signals for each of the 4 displays
    output reg [7:0] score   // Current score output to scoreboard (increments by 1 per completed round)
);

    // State machine definitions
    parameter IDLE = 0,        // Waiting for password verification
              SEL_DIFF = 1,    // User selecting difficulty level with btn3
              SHOW = 2,        // Displaying random numbers for 5 seconds
              WAIT_INPUT = 3,  // Waiting for user to input guesses
              CHECK = 4,       // Verifying if guess matches stored number
              UPDATE = 5,      // Moving to next number or completing round
              ROUND_END = 6,   // Round complete, waiting for next round start
              GAME_END = 7;    // Game over due to timeout or wrong guess
    
    reg [2:0] state;           // Current state of the game
    reg [1:0] difficulty;      // 0=dif1(2nums,30s), 1=dif2(3nums,40s), 2=dif3(4nums,50s)
    reg [3:0] stored_nums [0:3]; // Array to store random numbers in GUESSING ORDER (left to right)
    reg [1:0] num_req;         // How many numbers needed for current difficulty (2,3,4)
    reg [1:0] guess_idx;       // Which number user is currently guessing (0,1,2,3)
    reg [3:0] current_guess;   // Current guess value from switches
    reg [7:0] score_reg;       // Internal register to track score before output
    reg [2:0] show_pulse_cnt;  // Counts 1-second pulses from 0 to 4 (for 5 seconds)
    wire one_sec_show;         // 1-second pulse from show timer
    reg show_timer_en;         // Enable signal for the 5-second show timer
    
    // Button edge detection for debouncing
    reg btn1_prev, btn2_prev, btn3_prev;
    wire btn1_edge, btn2_edge, btn3_edge;
    
    // Edge detection logic
    assign btn1_edge = btn1 & ~btn1_prev;
    assign btn2_edge = btn2 & ~btn2_prev;
    assign btn3_edge = btn3 & ~btn3_prev;
    
    // Instantiate separate 1-second timer just for displaying numbers (5 seconds)
    onesecTimer_show show_timer(show_timer_en, one_sec_show, clk, rst);
    
    always @(posedge clk) begin
        // Store previous button states for edge detection
        btn1_prev <= btn1;
        btn2_prev <= btn2;
        btn3_prev <= btn3;
        
        if (rst == 1'b0) begin
            load_out <= 1'b0;
            start_out <= 1'b0;
            timer_en <= 1'b0;
            timer_reconfig <= 1'b0;
            timer_val <= 8'h30;
            logout <= 1'b0;
            diff_led <= 3'b001;
            disp_data <= 16'h0000;
            disp_en <= 4'b0000;
            score <= 8'd0;
            state <= IDLE;
            difficulty <= 2'd0;
            num_req <= 2'd2;
            guess_idx <= 2'd0;
            current_guess <= 4'd0;
            score_reg <= 8'd0;
            show_pulse_cnt <= 3'd0;
            show_timer_en <= 1'b0;
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
                    disp_en <= 4'b0000;
                    
                    if (pass_good == 1'b1) begin
                        state <= SEL_DIFF;
                        difficulty <= 2'd0;
                        diff_led <= 3'b001;
                        num_req <= 2'd2;
                        timer_val <= 8'h30;
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                
                SEL_DIFF: begin
                    timer_en <= 1'b0;
                    disp_en <= 4'b0000;
                    
                    if (btn3_edge == 1'b1) begin
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
                    else if (btn2_edge == 1'b1) begin
                        // Capture random numbers - LEFT TO RIGHT guessing order
                        if (difficulty == 2'd0) begin
                            // Difficulty 1: 2 numbers (left to right)
                            stored_nums[0] <= lfsr_q[7:4];   // First guess (leftmost display)
                            stored_nums[1] <= lfsr_q[3:0];   // Second guess (rightmost display)
                            disp_data <= {lfsr_q[7:4], lfsr_q[3:0], 8'h00};  // Shows on display4, display3
                            disp_en <= 4'b1100;  // Enable displays 4 and 3
                        end
                        else if (difficulty == 2'd1) begin
                            // Difficulty 2: 3 numbers (left to right)
                            stored_nums[0] <= lfsr_q[11:8];  // First guess (leftmost display)
                            stored_nums[1] <= lfsr_q[7:4];   // Second guess
                            stored_nums[2] <= lfsr_q[3:0];   // Third guess (rightmost display)
                            disp_data <= {lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0], 4'h0};  // Shows on display4,3,2
                            disp_en <= 4'b1110;  // Enable displays 4,3,2
                        end
                        else begin
                            // Difficulty 3: 4 numbers (left to right)
                            stored_nums[0] <= lfsr_q[15:12]; // First guess (leftmost display)
                            stored_nums[1] <= lfsr_q[11:8];  // Second guess
                            stored_nums[2] <= lfsr_q[7:4];   // Third guess
                            stored_nums[3] <= lfsr_q[3:0];   // Fourth guess (rightmost display)
                            disp_data <= {lfsr_q[15:12], lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0]};  // Shows on all displays
                            disp_en <= 4'b1111;  // Enable all displays
                        end
                        
                        timer_reconfig <= 1'b1;
                        timer_en <= 1'b1;
                        state <= SHOW;
                        show_pulse_cnt <= 3'd0;
                        show_timer_en <= 1'b1;
                    end
                    else begin
                        state <= SEL_DIFF;
                    end
                end
                
                SHOW: begin
                    timer_en <= 1'b1;
                    
                    if (one_sec_show == 1'b1) begin
                        if (show_pulse_cnt == 3'd4) begin
                            show_timer_en <= 1'b0;
                            state <= WAIT_INPUT;
                            guess_idx <= 2'd0;
                            disp_en <= 4'b0000;
                        end
                        else begin
                            show_pulse_cnt <= show_pulse_cnt + 1;
                            state <= SHOW;
                        end
                    end
                    else if (btn3_edge == 1'b1) begin
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
                    disp_en <= 4'b0000;
                    
                    if (time_out == 1'b1) begin
                        timer_en <= 1'b0;
                        state <= GAME_END;
                    end
                    else if (btn3_edge == 1'b1) begin
                        logout <= 1'b1;
                        timer_en <= 1'b0;
                        state <= IDLE;
                    end
                    else if (btn1_edge == 1'b1) begin
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
                        // ALL numbers guessed correctly! Add 1 point
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
                    disp_en <= 4'b0000;
                    
                    if (btn2_edge == 1'b1) begin
                        // Capture new random numbers - SAME left to right mapping
                        if (difficulty == 2'd0) begin
                            stored_nums[0] <= lfsr_q[7:4];
                            stored_nums[1] <= lfsr_q[3:0];
                            disp_data <= {lfsr_q[7:4], lfsr_q[3:0], 8'h00};
                            disp_en <= 4'b1100;
                        end
                        else if (difficulty == 2'd1) begin
                            stored_nums[0] <= lfsr_q[11:8];
                            stored_nums[1] <= lfsr_q[7:4];
                            stored_nums[2] <= lfsr_q[3:0];
                            disp_data <= {lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0], 4'h0};
                            disp_en <= 4'b1110;
                        end
                        else begin
                            stored_nums[0] <= lfsr_q[15:12];
                            stored_nums[1] <= lfsr_q[11:8];
                            stored_nums[2] <= lfsr_q[7:4];
                            stored_nums[3] <= lfsr_q[3:0];
                            disp_data <= {lfsr_q[15:12], lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0]};
                            disp_en <= 4'b1111;
                        end
                        
                        timer_reconfig <= 1'b1;
                        timer_en <= 1'b1;
                        state <= SHOW;
                        show_pulse_cnt <= 3'd0;
                        show_timer_en <= 1'b1;
                    end
                    else if (btn3_edge == 1'b1) begin
                        logout <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        state <= ROUND_END;
                    end
                end
                
                GAME_END: begin
                    timer_en <= 1'b0;
                    disp_en <= 4'b0000;
                    
                    if (btn2_edge == 1'b1) begin
                        score_reg <= 8'd0;
                        score <= 8'd0;
                        guess_idx <= 2'd0;
                        state <= SEL_DIFF;
                    end
                    else if (btn3_edge == 1'b1) begin
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
