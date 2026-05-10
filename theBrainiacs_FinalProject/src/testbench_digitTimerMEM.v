`timescale 1 ns/100 ps
module testbench_digitTimerMEM();
     reg clk;
     reg rst;
     reg timer_enable;
     reg timer_reconfig;
     reg [7:0] start_value;
     wire time_out;
     wire [3:0] tens_digit;
     wire [3:0] ones_digit;

     always
         begin
             clk = 1'b0;
             #10;
             clk = 1'b1;
             #10;
          end

digitTimerMEM DUT_digitTimerMEM(
    .timer_enable(timer_enable),
    .timer_reconfig(timer_reconfig),
    .start_value(start_value),
    .clk(clk),
    .rst(rst),
    .time_out(time_out),
    .tens_digit(tens_digit),
    .ones_digit(ones_digit)
);

    initial
      begin
         rst = 1'b1;
         timer_enable = 1'b0;
         timer_reconfig = 1'b0;
         start_value = 8'h30;

         @(posedge clk);
         @(posedge clk);
         #5 rst = 1'b0;
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         #5 rst = 1'b1;
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         #5 timer_reconfig = 1'b1;
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         #5 timer_reconfig = 1'b0;
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         #5 timer_enable = 1'b1;
      end
endmodule
