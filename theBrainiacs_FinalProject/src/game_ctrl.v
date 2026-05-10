//Manav Patel
//ECE:6370
// Memory Game Controller with Difficulty Selection, LFSR Random Numbers, and Score Tracking

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
    output reg [7:0] score   // Current score output to scoreboard
);

    // State machine definitions - each state represents a different phase of the game
    parameter IDLE = 0,        // Waiting for password verification
              SEL_DIFF = 1,    // User selecting difficulty level with btn3
              WAIT_START = 2,  // Ready to start, waiting for btn2 (not used in final)
              SHOW = 3,        // Displaying random numbers for 5 seconds
              WAIT_INPUT = 4,  // Waiting for user to input guesses
              CHECK = 5,       // Verifying if guess matches stored number
              UPDATE = 6,      // Incrementing score after correct guess
              ROUND_END = 7,   // Round complete, waiting for next round start
              GAME_END = 8;    // Game over due to timeout or wrong guess
    
    reg [3:0] state;           // Current state of the game
    reg [1:0] difficulty;      // 0=dif1(2nums,30s), 1=dif2(3nums,40s), 2=dif3(4nums,50s)
    reg [3:0] stored_nums [0:3]; // Array to store 2-4 random numbers (each 4 bits)
    reg [1:0] num_req;         // How many numbers needed for current difficulty (2,3,4)
    reg [1:0] guess_idx;       // Which number user is currently guessing (0,1,2,3)
    reg [3:0] current_guess;   // Current guess value from switches
    reg [7:0] score_reg;       // Internal register to track score before output
    reg [2:0] show_pulse_cnt;  // Counts 1-second pulses from 0 to 4 (for 5 seconds)
    reg show_5sec_done;        // Flag indicating 5 seconds has elapsed
    wire one_sec_show;         // 1-second pulse from show timer
    reg show_timer_en;         // Enable signal for the 5-second show timer
    
    // Instantiate separate 1-second timer just for displaying numbers (5 seconds)
    onesecTimer_show show_timer(show_timer_en, one_sec_show, clk, rst);
    
    // Main always block - everything happens on rising edge of clock
    always @(posedge clk) begin
        // Reset condition (active low - when rst = 0)
        if (rst == 1'b0) begin
            // Clear all output signals
            load_out <= 1'b0;        // Clear load output
            start_out <= 1'b0;       // Clear start output
            timer_en <= 1'b0;        // Disable timer
            timer_reconfig <= 1'b0;  // No timer reconfiguration
            timer_val <= 8'h30;      // Default timer value to 30 seconds (BCD)
            logout <= 1'b0;          // No logout signal
            diff_led <= 3'b001;      // Default to difficulty 1 (LED 1 on)
            disp_data <= 16'h0000;   // Clear display data
            disp_en <= 4'b0000;      // Turn off all displays
            score <= 8'd0;           // Reset score to 0
            state <= IDLE;           // Go to IDLE state
            difficulty <= 2'd0;      // Set difficulty to level 1
            num_req <= 2'd2;         // Difficulty 1 needs 2 numbers
            guess_idx <= 2'd0;       // Start at guess index 0
            current_guess <= 4'd0;   // Clear current guess
            score_reg <= 8'd0;       // Clear internal score register
            show_pulse_cnt <= 3'd0;  // Reset 5-second counter
            show_5sec_done <= 1'b0;  // 5 seconds not done
            show_timer_en <= 1'b0;   // Disable show timer
            stored_nums[0] <= 4'd0;  // Clear stored number slot 0
            stored_nums[1] <= 4'd0;  // Clear stored number slot 1
            stored_nums[2] <= 4'd0;  // Clear stored number slot 2
            stored_nums[3] <= 4'd0;  // Clear stored number slot 3
        end
        else begin
            // Default assignments (cleared each clock cycle unless set)
            load_out <= 1'b0;        // Default: no load pass-through
            start_out <= 1'b0;       // Default: no start pass-through
            timer_reconfig <= 1'b0;  // Default: no timer reconfig
            logout <= 1'b0;          // Default: no logout
            
            // State machine - handle different game phases
            case (state)
                // IDLE state - waiting for password verification
                IDLE: begin
                    timer_en <= 1'b0;           // Timer disabled
                    score_reg <= 8'd0;          // Reset score register
                    score <= 8'd0;              // Reset score output
                    guess_idx <= 2'd0;          // Reset guess index
                    show_5sec_done <= 1'b0;     // Reset show flag
                    show_pulse_cnt <= 3'd0;     // Reset pulse counter
                    show_timer_en <= 1'b0;      // Disable show timer
                    disp_en <= 4'b0000;         // Turn off all displays
                    
                    // Check if password was verified by external module
                    if (pass_good == 1'b1) begin
                        state <= SEL_DIFF;      // Move to difficulty selection
                        difficulty <= 2'd0;     // Start at difficulty 1
                        diff_led <= 3'b001;     // LED shows difficulty 1
                        num_req <= 2'd2;        // Need 2 numbers for difficulty 1
                        timer_val <= 8'h30;     // 30 seconds for difficulty 1
                    end
                    else begin
                        state <= IDLE;          // Stay in IDLE until password is good
                    end
                end
                
                // SEL_DIFF state - user selects difficulty by pressing btn3
                SEL_DIFF: begin
                    timer_en <= 1'b0;           // Timer stays disabled
                    disp_en <= 4'b0000;         // Displays off during selection
                    
                    // Check if btn3 is pressed (cycle difficulty)
                    if (btn3 == 1'b1) begin
                        // Cycle through difficulties: 1 -> 2 -> 3 -> 1
                        if (difficulty == 2'd0) begin
                            difficulty <= 2'd1;     // Move to difficulty 2
                            diff_led <= 3'b010;     // LED shows difficulty 2
                            num_req <= 2'd3;        // Need 3 numbers
                            timer_val <= 8'h40;     // 40 seconds for difficulty 2
                        end
                        else if (difficulty == 2'd1) begin
                            difficulty <= 2'd2;     // Move to difficulty 3
                            diff_led <= 3'b100;     // LED shows difficulty 3
                            num_req <= 2'd4;        // Need 4 numbers
                            timer_val <= 8'h50;     // 50 seconds for difficulty 3
                        end
                        else begin
                            difficulty <= 2'd0;     // Back to difficulty 1
                            diff_led <= 3'b001;     // LED shows difficulty 1
                            num_req <= 2'd2;        // Need 2 numbers
                            timer_val <= 8'h30;     // 30 seconds for difficulty 1
                        end
                        state <= SEL_DIFF;          // Stay in selection state
                    end
                    // Check if btn2 is pressed (start game)
                    else if (btn2 == 1'b1) begin
                        // Capture random numbers from LFSR based on difficulty
                        if (difficulty == 2'd0) begin
                            // Difficulty 1: need 2 numbers
                            stored_nums[0] <= lfsr_q[3:0];   // First number = bits 3-0
                            stored_nums[1] <= lfsr_q[7:4];   // Second number = bits 7-4
                            disp_data <= {8'h00, lfsr_q[7:4], lfsr_q[3:0]}; // Display data (2 digits)
                            disp_en <= 4'b0011;              // Enable only displays 1 and 2
                        end
                        else if (difficulty == 2'd1) begin
                            // Difficulty 2: need 3 numbers
                            stored_nums[0] <= lfsr_q[3:0];   // First number = bits 3-0
                            stored_nums[1] <= lfsr_q[7:4];   // Second number = bits 7-4
                            stored_nums[2] <= lfsr_q[11:8];  // Third number = bits 11-8
                            disp_data <= {4'h0, lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0]}; // 3 digits
                            disp_en <= 4'b0111;              // Enable displays 1,2,3
                        end
                        else begin
                            // Difficulty 3: need 4 numbers
                            stored_nums[0] <= lfsr_q[3:0];   // First number = bits 3-0
                            stored_nums[1] <= lfsr_q[7:4];   // Second number = bits 7-4
                            stored_nums[2] <= lfsr_q[11:8];  // Third number = bits 11-8
                            stored_nums[3] <= lfsr_q[15:12]; // Fourth number = bits 15-12
                            disp_data <= {lfsr_q[15:12], lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0]}; // 4 digits
                            disp_en <= 4'b1111;              // Enable all 4 displays
                        end
                        
                        timer_reconfig <= 1'b1;    // Reset timer to configured value
                        timer_en <= 1'b1;          // Start the timer
                        state <= SHOW;             // Move to SHOW state
                        show_pulse_cnt <= 3'd0;    // Reset 5-second counter
                        show_5sec_done <= 1'b0;    // 5 seconds not done yet
                        show_timer_en <= 1'b1;     // Enable the 5-second show timer
                    end
                    else begin
                        state <= SEL_DIFF;         // Stay in selection until btn2 pressed
                    end
                end
                
                // SHOW state - display random numbers for 5 seconds
                SHOW: begin
                    timer_en <= 1'b1;              // Keep main timer running
                    
                    // Check if 1-second pulse occurred from show timer
                    if (one_sec_show == 1'b1) begin
                        // Count 5 pulses (0,1,2,3,4 = 5 seconds)
                        if (show_pulse_cnt == 3'd4) begin
                            show_5sec_done <= 1'b1;    // 5 seconds complete
                            show_timer_en <= 1'b0;     // Disable show timer
                            state <= WAIT_INPUT;       // Move to input waiting state
                            guess_idx <= 2'd0;         // Reset guess index to first number
                            disp_en <= 4'b0000;        // Turn off displays
                        end
                        else begin
                            show_pulse_cnt <= show_pulse_cnt + 1; // Increment counter
                            state <= SHOW;             // Continue showing
                        end
                    end
                    // Check for logout during show state
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;              // Send logout signal to password module
                        timer_en <= 1'b0;            // Stop timer
                        show_timer_en <= 1'b0;       // Stop show timer
                        state <= IDLE;               // Return to IDLE state
                    end
                    else begin
                        state <= SHOW;               // Continue showing numbers
                    end
                end
                
                // WAIT_INPUT state - waiting for user to input guesses
                WAIT_INPUT: begin
                    timer_en <= 1'b1;              // Keep timer running
                    disp_en <= 4'b0000;            // Displays off during input
                    
                    // Check if timer expired
                    if (time_out == 1'b1) begin
                        timer_en <= 1'b0;          // Stop timer
                        state <= GAME_END;         // Game over
                    end
                    // Check for logout during input
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;            // Send logout signal
                        timer_en <= 1'b0;          // Stop timer
                        state <= IDLE;             // Return to IDLE
                    end
                    // Check if btn1 pressed (load guess from switches)
                    else if (btn1 == 1'b1) begin
                        current_guess <= sw;       // Store switch values as current guess
                        state <= CHECK;            // Move to CHECK state to verify
                    end
                    else begin
                        state <= WAIT_INPUT;       // Continue waiting for input
                    end
                end
                
                // CHECK state - verify if guess matches stored number
                CHECK: begin
                    timer_en <= 1'b1;              // Keep timer running
                    load_out <= 1'b1;              // Pass btn1 through to other modules
                    
                    // Compare user's guess with stored number at current index
                    if (current_guess == stored_nums[guess_idx]) begin
                        state <= UPDATE;           // Correct guess - move to UPDATE
                    end
                    else begin
                        timer_en <= 1'b0;          // Wrong guess - stop timer
                        state <= GAME_END;         // Game over
                    end
                end
                
                // UPDATE state - increment score after correct guess
                UPDATE: begin
                    timer_en <= 1'b1;              // Keep timer running
                    score_reg <= score_reg + 1;    // Increment internal score register
                    score <= score_reg + 1;        // Output new score value
                    
                    // Check if all numbers have been guessed correctly
                    if (guess_idx + 1 == num_req) begin
                        state <= ROUND_END;        // Round complete - move to ROUND_END
                    end
                    else begin
                        guess_idx <= guess_idx + 1; // Move to next number
                        state <= WAIT_INPUT;       // Wait for next guess
                    end
                end
                
                // ROUND_END state - all numbers correct, waiting for next round
                ROUND_END: begin
                    timer_en <= 1'b0;              // Stop timer
                    disp_en <= 4'b0000;            // Turn off displays
                    
                    // Check if btn2 pressed (start next round)
                    if (btn2 == 1'b1) begin
                        // Capture new random numbers from LFSR for next round
                        if (difficulty == 2'd0) begin
                            // Difficulty 1: capture 2 new numbers
                            stored_nums[0] <= lfsr_q[3:0];
                            stored_nums[1] <= lfsr_q[7:4];
                            disp_data <= {8'h00, lfsr_q[7:4], lfsr_q[3:0]};
                            disp_en <= 4'b0011;
                        end
                        else if (difficulty == 2'd1) begin
                            // Difficulty 2: capture 3 new numbers
                            stored_nums[0] <= lfsr_q[3:0];
                            stored_nums[1] <= lfsr_q[7:4];
                            stored_nums[2] <= lfsr_q[11:8];
                            disp_data <= {4'h0, lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0]};
                            disp_en <= 4'b0111;
                        end
                        else begin
                            // Difficulty 3: capture 4 new numbers
                            stored_nums[0] <= lfsr_q[3:0];
                            stored_nums[1] <= lfsr_q[7:4];
                            stored_nums[2] <= lfsr_q[11:8];
                            stored_nums[3] <= lfsr_q[15:12];
                            disp_data <= {lfsr_q[15:12], lfsr_q[11:8], lfsr_q[7:4], lfsr_q[3:0]};
                            disp_en <= 4'b1111;
                        end
                        
                        timer_reconfig <= 1'b1;    // Reset timer for new round
                        timer_en <= 1'b1;          // Start timer again
                        state <= SHOW;             // Show new numbers
                        show_pulse_cnt <= 3'd0;    // Reset 5-second counter
                        show_5sec_done <= 1'b0;    // Reset show flag
                        show_timer_en <= 1'b1;     // Enable show timer
                    end
                    // Check for logout during round end
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;            // Send logout signal
                        state <= IDLE;             // Return to IDLE
                    end
                    else begin
                        state <= ROUND_END;        // Wait for btn2 to start next round
                    end
                end
                
                // GAME_END state - game over due to timeout or wrong guess
                GAME_END: begin
                    timer_en <= 1'b0;              // Stop timer
                    disp_en <= 4'b0000;            // Turn off displays
                    
                    // Check if btn2 pressed to restart game
                    if (btn2 == 1'b1) begin
                        score_reg <= 8'd0;         // Reset score
                        score <= 8'd0;             // Clear score output
                        guess_idx <= 2'd0;         // Reset guess index
                        state <= SEL_DIFF;         // Go back to difficulty selection
                    end
                    // Check for logout during game end
                    else if (btn3 == 1'b1) begin
                        logout <= 1'b1;            // Send logout signal
                        state <= IDLE;             // Return to IDLE
                    end
                    else begin
                        state <= GAME_END;         // Stay in game over state
                    end
                end
                
                // Default case - if state is invalid, go to IDLE
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
