//ECE:6370
//Manav Patel 2068416
//Lab4_PATEL_Manav - TEST VERSION
// This test version hardcodes display to show 1234 to verify displays work

module TopLevelMEM(
    input [3:0] Password_Switches,  // 4-bit switches for password entry
    input [3:0] Player1_Switches,   // 4-bit switches for guesses
    input RNG_Button,               // Button 2 - start game
    input Pass_Button,              // Button 3 - submit password / cycle difficulty
    input Load_Button_1,            // Button 1 - load guess
    input clk,                      // Clock signal
    input rst,                      // Reset signal (active low)
    
    output [2:0] diff_led,          // 3-bit output for difficulty LEDs
    output [6:0] Sevenseg_1,        // 7-segment display 1 (rightmost)
    output [6:0] Sevenseg_2,        // 7-segment display 2
    output [6:0] Sevenseg_3,        // 7-segment display 3
    output [6:0] Sevenseg_4,        // 7-segment display 4 (leftmost)
    output [6:0] Sevenseg_5,        // 7-segment display 5 (timer ones digit)
    output [6:0] Sevenseg_6         // 7-segment display 6 (timer tens digit)
);

    // Internal wire declarations
    wire Pass_Button_wire, Load_Button_1_wire, RNG_Button_wire;
    wire load_out, start_out;
    wire timer_enable, timer_reconfig, time_out_wire;
    wire logout;
    wire pass_good;
    wire [3:0] Loaded_Player1;
    wire [7:0] timer_val;
    wire [15:0] disp_data;
    wire [3:0] timer_ones, timer_tens;
    wire [7:0] score;

    // Button shapers for debouncing
    ButtonShaper Pass_BS(Pass_Button, Pass_Button_wire, clk, rst);
    ButtonShaper Load1_BS(Load_Button_1, Load_Button_1_wire, clk, rst);
    ButtonShaper RNG_BS(RNG_Button, RNG_Button_wire, clk, rst);

    // Access Controller - password verification
    AccesControllerMEM DUT_AccessController(Pass_Button_wire, Password_Switches, logout, pass_good, clk, rst);

    // Game Controller - TEST VERSION (hardcodes 1234 on display)
    game_ctrl DUT_GameController(
        .clk(clk),
        .rst(rst),
        .pass_good(pass_good),
        .btn1(Load_Button_1_wire),
        .btn2(RNG_Button_wire),
        .btn3(Pass_Button_wire),
        .time_out(time_out_wire),
        .sw(Player1_Switches),
        .load_out(load_out),
        .start_out(start_out),
        .timer_en(timer_enable),
        .timer_reconfig(timer_reconfig),
        .timer_val(timer_val),
        .logout(logout),
        .diff_led(diff_led),
        .disp_data(disp_data),
        .score(score)
    );

    // Load Register - stores player's guess
    LoadRegister Load_reg1(Player1_Switches, Loaded_Player1, clk, rst, load_out);

    // Digital Timer
    digitTimerMEM DUT_Timer(timer_enable, timer_reconfig, timer_val, clk, rst, time_out_wire, timer_tens, timer_ones);

    // Seven segment decoders for game number displays
    sevenseg Zseg_4(disp_data[15:12], Sevenseg_4);  // Leftmost - should show 1
    sevenseg Zseg_3(disp_data[11:8], Sevenseg_3);   // Should show 2
    sevenseg Zseg_2(disp_data[7:4], Sevenseg_2);    // Should show 3
    sevenseg Zseg_1(disp_data[3:0], Sevenseg_1);    // Rightmost - should show 4

    // Seven segment decoders for timer display
    sevenseg Zseg_5(timer_ones, Sevenseg_5);   // Timer ones digit
    sevenseg Zseg_6(timer_tens, Sevenseg_6);   // Timer tens digit

endmodule
