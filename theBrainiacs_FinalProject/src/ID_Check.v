module ID_Check(digit, btn, logout, guest, rom_value, matched_id, addr, internal_id, clk, rst);
    input btn, logout, clk, rst; // btn press and if logout is signaled
    input [3:0] digit;  // user input digit
    input [15:0] rom_value;  // value retrieved from ROM
    output reg matched_id, guest;   // if a match occurs 
    output reg [2:0] addr, internal_id; // address for ID ROM andinternal ID used for password
    reg [15:0] saved_id, rom_store_id; // id stored from user entered digits & id rom stored from input rom_value since rom_value is driven by ID_ROM module
    reg [3:0] State; // state machine
    parameter DIG1 = 0, DIG2 = 1, DIG3 = 2, DIG4 = 3, FETCH = 4, CYC1 = 5, CYC2 = 6, CATCH = 7, COMP = 8, STATUS = 9, GUEST = 10;

    always @(posedge clk) begin
        if(rst == 1'b0) begin
            matched_id <= 1'b0; 
            addr <= 3'b000;
            internal_id <= 3'b000;
            State <= DIG1;
            guest <= 1'b0;
        end
        else begin
            case(State) 

                DIG1: begin
                    guest <= 1'b0;
                    matched_id <= 1'b0;
                    if(btn == 1'b1) begin
                        saved_id[15:12] <= digit;
                        State <= DIG2;
                    end
                    else begin
                        State <= DIG1;
                    end
                end

                DIG2: begin
                    if(btn == 1'b1) begin
                        saved_id[11:8] <= digit;
                        State <= DIG3;
                    end
                    else begin
                        State <= DIG2;
                    end
                end

                DIG3: begin
                    if(btn == 1'b1) begin
                        saved_id[7:4] <= digit;
                        State <= DIG4;
                    end
                    else begin
                        State <= DIG3;
                    end
                end

                DIG4: begin
                    if(btn == 1'b1) begin
                        saved_id[3:0] <= digit;
                        State <= FETCH;
                    end
                    else begin
                        State <= DIG4;
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
                    rom_store_id <= rom_value;
                    State <= COMP;
                end

                COMP: begin 
                    if(rom_store_id == saved_id) begin
                        State <= GUEST;
                    end
                    else begin
                        State <= STATUS;
                    end
                end

                GUEST: begin 
                    matched_id <= 1'b1; // a match has been found, either guest or a valid ID
                    internal_id <= addr;// set internal ID to the address that was last checked
                    if(logout == 1'b1) begin 
                        addr <= 3'b000;
                        State <= DIG1;
                    end
                    else if (saved_id == 16'h8888) begin
                        // send out guest signal and wait for logout
                        guest <= 1'b1;
                        State <= GUEST;
                    end
                    else begin
                        State <= GUEST;
                    end
                end

                STATUS: begin
                    if(rom_store_id == 16'hFFFF || addr == 3'b111) begin
                        addr <= 3'b000;
                        State <= DIG1;    
                    end
                    else begin
                        addr <= addr + 1;
                        State <= FETCH;
                    end
                end

            endcase
        end
    end
endmodule