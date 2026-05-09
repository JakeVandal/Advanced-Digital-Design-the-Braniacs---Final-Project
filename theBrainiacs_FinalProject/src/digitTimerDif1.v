
module digitTimerDif1(timer_enable,timer_reconfig,time_out,tens_digit,ones_digit,clk,rst);
    input timer_enable;
    input timer_reconfig;
    input clk;
    input rst;

    output time_out;
    output[3:0] tens_digit;
    output[3:0] ones_digit;
    reg time_out;
    reg[3:0] tens_digit;
    reg[3:0] ones_digit;    

    wire one_sec_pulse;

onesecTimer first_timer(timer_enable,one_sec_pulse,clk,rst);
    always @(posedge clk) begin
        if (rst == 1'b0) begin
            ones_digit <= 4'd0;
            tens_digit <= 4'd0;
            time_out <= 1'b0;
        end
        else begin
            time_out <= 1'b0;  // Default to 0
            
            // Timer reconfig pulse - reset to 99
            if (timer_reconfig == 1'b1) begin
                ones_digit <= 4'd0;
                tens_digit <= 4'd3;
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
