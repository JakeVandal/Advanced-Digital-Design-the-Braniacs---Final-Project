module Password_Check1(digit, btn, logout_game_control, guest, matched_id, internal_id, rom_value, addr, logout, guest_pswd, internal_id_out, logged_in, clk, rst);
    input btn, logout_game_control, guest, matched_id, clk, rst;
    input [2:0] internal_id; // internal ID from ID_Check
    input [3:0] digit; // digit entered by user
    input [23:0] rom_value; // password from password ROM
    output reg logout, logged_in, guest_pswd; // if the password matches, if the user is a guest, and if the user is logged in
    output reg [2:0] addr, internal_id_out; // address for password ROM and internal ID to be used for password check
    reg [23:0] saved_password, rom_store_pswd; // password stored from user entered digits & password rom stored from input rom_value since rom_value is driven by ID_ROM module
    reg [3:0] State; // state machine
    reg [2:0] Cnt; // counter for wait
    parameter DIG1 = 0, DIG2 = 1, DIG3 = 2, DIG4 = 3, DIG5 = 4, DIG6 = 5, FETCH = 6, CYC1 = 7, CYC2 = 8, CATCH = 9, COMP = 10, PASSED = 11, WAIT = 12;

    always @(posedge clk) begin
        if(rst == 1'b0) begin
            logout <= 1'b0;
            logged_in <= 1'b0;
            guest_pswd <= guest;
            internal_id_out <= 3'b000;
            addr <= 3'b000;
            saved_password <= 16'h0000;
            State <= DIG1;
            Cnt <= 4;
        end
        if(matched_id == 1'b0) begin
            logout <= 1'b0;
            logged_in <= 1'b0;
            guest_pswd <= guest;
            internal_id_out <= 3'b000;
            addr <= 3'b000;
            saved_password <= 16'h0000;
            State <= DIG1;
            Cnt <= 4;
        end
        else begin
            case(State)
                
                DIG1: begin
                    addr <= internal_id; // set address to internal ID from ID_Check so that we can get the correct password from the password ROM
                    Cnt <= 4;
                    guest_pswd <= guest;
                    if(matched_id == 1'b1) begin  // only proceed if ID matched
                        if(btn == 1'b1) begin
                            saved_password[23:20] <= digit;
                            State <= DIG2;
                        end
                        else begin
                            State <= DIG1;
                        end
                    end
                    else begin
                        State <= DIG1;
                    end
                end

                DIG2: begin
                    if(btn == 1'b1) begin
                        saved_password[19:16] <= digit;
                        State <= DIG3;
                    end
                    else begin
                        State <= DIG2;
                    end
                end

                DIG3: begin
                    if(btn == 1'b1) begin
                        saved_password[15:12] <= digit;
                        State <= DIG4;
                    end
                    else begin
                        State <= DIG3;
                    end
                end

                DIG4: begin
                    if(btn == 1'b1) begin
                        saved_password[11:8] <= digit;
                        State <= DIG5;
                    end
                    else begin
                        State <= DIG4;
                    end
                end

                DIG5: begin
                    if(btn == 1'b1) begin
                        saved_password[7:4] <= digit;
                        State <= DIG6;
                    end
                    else begin
                        State <= DIG5;
                    end
                end

                DIG6: begin
                    if(btn == 1'b1) begin
                        saved_password[3:0] <= digit;
                        State <= FETCH;
                    end
                    else begin
                        State <= DIG6;
                    end
                end

                FETCH: begin
                    internal_id_out <= internal_id;
                    State <= CYC1;
                end

                CYC1: begin
                    State <= CYC2;
                end

                CYC2: begin
                    State <= CATCH;
                end

                CATCH: begin
                    rom_store_pswd <= rom_value;
                    State <= COMP;
                end

                COMP: begin
                    if(rom_store_pswd == saved_password) begin 
                        State <= PASSED;
                    end
                    else begin 
                        State <= WAIT;
                    end
                end

                PASSED: begin
                    if(logout_game_control == 1'b1) begin // only care about logout if we actually have passed first
                        logout <= 1'b1;
                        State <= WAIT;
                    end
                    else begin
                        logged_in <= 1'b1;
                        State <= PASSED;
                    end
                end

                WAIT: begin
                    logout <= 1'b0;
                    if(Cnt == 0) begin  
                        State <= DIG1;
                    end
                    else begin
                        Cnt <= Cnt - 1;
                        State <= WAIT;
                    end
                end
                
            endcase
        end
        
    end

endmodule