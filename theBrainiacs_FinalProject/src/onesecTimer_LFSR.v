// Manav Patel
// ECE: 6370
// 1 second timer using 16-bit LFSR instead of counter for 1ms base timing
// All in one module - LFSR built directly into the timer
// Target LFSR value determined: 50,000 cycles = 0xDB6C
// LFSR resets to 0xFFFF after hitting target
module onesecTimer_LFSR(enable, signal_out, clk, rst);
    input enable;
    output signal_out;
    input clk, rst;
    reg signal_out;
    reg [6:0] count100;      // counts 0 to 100 (100ms increments)
    reg [3:0] count10;       // counts 0 to 10 (1 second total)  
    // LFSR registers and wires
    reg [15:0] lfsr;
    wire feedback;  
    // Feedback from (bit 15)
    assign feedback = lfsr[15];  
    // Target value = 0xDB6C (50,000 decimal)
    localparam [15:0] TARGET_LFSR_VALUE = 16'hDB6C; 
    wire lfsr_hit_target = (lfsr == TARGET_LFSR_VALUE);// cheack for lfsr and value  
    always @(posedge clk)
    begin
        if(rst == 1'b0)
        begin
            // Reset all counters
            count100 <= 7'd0;
            count10 <= 4'd0;
            signal_out <= 1'b0;
            // Initialize LFSR to 0xFFFF
            lfsr <= 16'hFFFF;
        end
        else
        begin
            if(enable == 1'b1)
            begin
                signal_out <= 1'b0;
                
                // When LFSR hits target value, reset to 0xFFFF first
                if(lfsr_hit_target)
                begin
                    // Reset LFSR to 0xFFFF to restart the sequence
                    lfsr <= 16'hFFFF;
                    
                    // Handle the counter logic
                    if(count100 == 7'd100)
                    begin
                        count100 <= 7'd0;
                        
                        if(count10 == 4'd10)
                        begin
                            count10 <= 4'd0;
                            signal_out <= 1'b1;
                        end
                        else
                        begin
                            count10 <= count10 + 1;
                        end
                    end
                    else
                    begin
                        count100 <= count100 + 1;
                    end
                end
                else
                begin
                    // Normal LFSR shift operation
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
        end
    end
endmodule
