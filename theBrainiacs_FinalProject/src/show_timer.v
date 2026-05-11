// Manav Patel
//ECE: 6370

//This module is a 1 second timer that will output a pulse when 1 second timer is reached this is done with embedding 3 counters withing each other all adding up to 50 million.


module onesecTimer_show(enable,signal_out,clk,rst);
    input enable;
    output signal_out;
    input clk,rst;

    reg signal_out;
    reg [15:0] count1ms;
    reg [6:0] count100;
    reg [3:0] count10;
    //wire enable_100;

//countTo100 DUT_countTo100(enable_100,signal_out,clk,rst);

    always@(posedge clk)
       begin
          if(rst == 1'b0)
             begin
                  count1ms <= 16'd0;
                  count100 <= 7'd0;
                  count10 <= 4'd0;
                  signal_out <=1'b0;
             end
          else
             begin
               if(enable == 1)
                 begin
                  signal_out <=1'b0;
                  if(count1ms == 16'd50000)// cheack should be 50,000
                    begin
                        count1ms <= 16'd0;
                        if(count100 == 7'd100)// cheack should be 100
                           begin
                              count100 <= 7'd0;
                              if(count10 == 4'd10)// cheack should be 10
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
                        count1ms <= count1ms + 1;
                    end
                 end
                
             end
       end

endmodule
