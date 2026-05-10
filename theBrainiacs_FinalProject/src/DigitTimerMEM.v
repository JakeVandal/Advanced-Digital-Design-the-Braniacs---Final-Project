//Manav Patel
//ECE:6370
// Configurable countdown timer for Memory Game
// Start value can be set from 0-99 via start_value input

module digitTimerMEM(
    input timer_enable,
    input timer_reconfig,
    input [7:0] start_value,     // BCD start value
    input clk,
    input rst,
    output reg time_out,
    output reg [3:0] tens_digit,
    output reg [3:0] ones_digit
);

    wire one_sec_pulse;

    onesecTimer first_timer(timer_enable, one_sec_pulse, clk, rst);

    always @(posedge clk) begin
        if (rst == 1'b0) begin
            ones_digit <= 4'd0;
            tens_digit <= 4'd0;
            time_out <= 1'b0;
        end
        else begin
            time_out <= 1'b0;  // Default to 0
            
            // Timer reconfig pulse - reset to start_value
            if (timer_reconfig == 1'b1) begin
                // Convert start_value to BCD digits
                // start_value is in BCD format: upper 4 bits = tens, lower 4 bits = ones
                tens_digit <= start_value[7:4];
                ones_digit <= start_value[3:0];
            end
            // Countdown on each 1-second pulse
            else if (one_sec_pulse == 1'b1) begin
                
                // Check if timer reached 00
                if (tens_digit == 4'd0 && ones_digit == 4'd0) begin
                    time_out <= 1'b1;  // Send timeout pulse
                    // Stay at 00
                end
                else begin
                    // Countdown with borrow
                    if (ones_digit == 4'd0) begin
                        ones_digit <= 4'd9;
                        tens_digit <= tens_digit - 1;
                    end
                    else begin
                        ones_digit <= ones_digit - 1;
                    end
                end
            end
        end
    end

endmodule
