`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/05 12:47:51
// Design Name: 
// Module Name: elock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module elock_top (
    input clk,
    input rst,                  
    input btn_ENTER,
    input btn_next_digit,
    input btn_next_number,
    
    // display 
    output reg [3:0] display1,
    output reg [3:0] display2,
    output reg [3:0] display3,
    output reg [3:0] display4,
    
    // LED 
    output [3:0] led,           // indicate the digit currently using (controled by number_select_save )
    output reg led_r,           
    output reg led_g,           
    output reg led_b            
);


    // define
    localparam IDLE       = 3'd0;
    localparam PW_SELECT  = 3'd1;
    localparam PW_ENTER   = 3'd2;
    localparam CHECK_PW   = 3'd3;
    localparam PASS       = 3'd4;
    localparam WRONG      = 3'd5;
    localparam COUNT_DOWN = 3'd6;
    localparam SAVE_PW    = 3'd7;

    reg [2:0] current_state, next_state;
    
    // Password storage register
    reg [15:0] correct_pw_reg;   
    
    // the start pulse: This pulse will only be 1 in the clock cycle immediately following the switch to PW_SELECT or PW_ENTER.
    // record the previous state (one clk ago)
    reg [2:0] prev_state; 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_state <= PW_SELECT; // initial state
        end else begin
            prev_state <= current_state;
        end
    end
    // the pulse
    wire start_pw_select_pulse = ((current_state == PW_SELECT) && (prev_state != PW_SELECT)) ||
                                 ((current_state == PW_ENTER)  && (prev_state != PW_ENTER));
    
    
    
    wire [3:0] save1, save2, save3, save4;
    wire [3:0] num_d1, num_d2, num_d3, num_d4; // display output from number_select_save
    wire [15:0] entered_pw;
    assign entered_pw = {save4, save3, save2, save1}; 

    reg [7:0] sec_timer;
    reg [7:0] cooling_time;
    reg [3:0] attempt_count;

    // btn debounce and pulse processing
    wire btn_ENTER_deb, btn_ENTER_pos;
    wire btn_rst_deb, btn_rst_pos;
    wire btn_next_digit_deb, btn_next_digit_pos;
    BTN_DEB deb_enter(.clk(clk), .rst(rst), .btn(btn_ENTER), .btn_deb(btn_ENTER_deb));
    BTN_DEB deb_rst(.clk(clk), .rst(rst), .btn(rst), .btn_deb(btn_rst_deb));
    BTN_DEB deb_next_digit(.clk(clk), .rst(rst), .btn(btn_next_digit), .btn_deb(btn_next_digit_deb));
    Pulse_GEN pulse_enter(.clk(clk), .rst(rst), .in(btn_ENTER_deb), .out(btn_ENTER_pos));
    Pulse_GEN pulse_rst(.clk(clk), .rst(rst), .in(btn_rst_deb), .out(btn_rst_pos));
    Pulse_GEN pulse_next_digit(.clk(clk), .rst(rst), .in(btn_next_digit_deb), .out(btn_next_digit_pos));

    // one second pulse generator ( 125MHz ) 
    reg [26:0] clk_cnt;
    wire sec_pulse = (clk_cnt == 27'd124999999);//124999999 //test
    always @(posedge clk or posedge rst) begin
        if (rst) clk_cnt <= 27'd0;
        else if (sec_pulse) clk_cnt <= 27'd0;
        else clk_cnt <= clk_cnt + 1'b1;
    end

    // the number input module 
    number_select_save num_core (
        .clk(clk), 
        .rst(rst), 
        .start(start_pw_select_pulse),
        .enter(btn_ENTER_pos), 
        .next_digit(btn_next_digit), 
        .next_number(btn_next_number),
        .digit1(num_d1), .digit2(num_d2), .digit3(num_d3), .digit4(num_d4),
        .save1(save1), .save2(save2), .save3(save3), .save4(save4),
        .led(led)  // led[3:0] 
    );

    // display mux
    always @(*) begin
        case (current_state)
            WRONG: begin
                display1 = 4'd0;          
                display2 = 4'd0;          
                display3 = 4'd0;          
                display4 = attempt_count; 
            end
            COUNT_DOWN: begin 
                display1 = sec_timer % 10;
                display2 = sec_timer / 10;
                display3 = 4'd0;
                display4 = 4'd0;
            end
            IDLE: begin
                display1 = 4'd0;          
                display2 = 4'd0;          
                display3 = 4'd0;          
                display4 = 4'd0; 
            end
            default: begin
                display1 = num_d1;
                display2 = num_d2;
                display3 = num_d3;
                display4 = num_d4;
            end
        endcase
    end
    
    // rgbLED
    always @(*) begin
        case (current_state)
            IDLE: begin
                led_r <= 1'b1;
                led_g <= 1'b1;
                led_b <= 1'b1;
            end
            PW_SELECT: begin
                led_r <= 1'b1;
                led_g <= 1'b1;
                led_b <= 1'b0;
            end
            SAVE_PW: begin
                led_r <= 1'b0;
                led_g <= 1'b0;
                led_b <= 1'b0;
            end
            PW_ENTER: begin
                led_r <= 1'b0;
                led_g <= 1'b0;
                led_b <= 1'b1;
            end
            CHECK_PW: begin
                led_r <= 1'b0;
                led_g <= 1'b0;
                led_b <= 1'b0;
            end
            PASS: begin
                led_r <= 1'b0;
                led_g <= 1'b1;
                led_b <= 1'b0;
            end
            WRONG: begin
                led_r <= 1'b1;
                led_g <= 1'b0;
                led_b <= 1'b0;
            end
            COUNT_DOWN: begin 
                led_r <= 1'b1;
                led_g <= 1'b0;
                led_b <= 1'b0;
            end
            default: begin
                led_r <= 1'b0;
                led_g <= 1'b0;
                led_b <= 1'b0;
            end
        endcase
    end
    
    
    
    
    // FSM main
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= PW_SELECT;
            correct_pw_reg <= {4'd0, 4'd0, 4'd0, 4'd0}; //reset the pw 0000
            attempt_count <= 4'd0;
            sec_timer <= 8'd0; //?
            cooling_time <= 8'd0;
            
        end 
        else begin
            case (current_state)
                IDLE: begin
                    if (btn_ENTER_pos) current_state <= PW_ENTER;
                end

                PW_SELECT: begin
                    if (btn_ENTER_pos) current_state <= SAVE_PW;
                end
                
                SAVE_PW: begin
                    correct_pw_reg <= entered_pw; 
                    current_state <= PW_ENTER;     // automatically skip to the next step after saving
                end

                PW_ENTER: begin
                    if (btn_ENTER_pos) current_state <= CHECK_PW;
                end

                CHECK_PW: begin
                    if (entered_pw == correct_pw_reg) begin
                        current_state <= PASS;
                        attempt_count <= 4'd0; // reset attempt count
                    end else begin
                        current_state <= WRONG;
                        attempt_count <= attempt_count + 1'b1;
                        sec_timer <= 8'd3;     // WRONG state keeping time
                        
                        // calculate the cooldown time
                        if (attempt_count < 4'd9) 
                            cooling_time <= (attempt_count + 1'b1) * 8'd10;
                        else 
                            cooling_time <= 8'd99;
                    end
                end

                PASS: begin
                    if (btn_ENTER_pos) begin
                        current_state <= IDLE;
                    end else if (btn_next_digit_pos) begin //replace rst with btn_next_digit for
                        current_state <= PW_SELECT;
                    end 
                end

                WRONG: begin
                    if (sec_pulse) begin
                        if (sec_timer > 8'd1) begin
                            sec_timer <= sec_timer - 1'b1;
                        end else begin
                            // start COUNT_DOWN after 3s 
                            current_state <= COUNT_DOWN;
                            sec_timer <= cooling_time; // load cooldown time
                        end
                    end
                end

                COUNT_DOWN: begin
                    // update countdown every second
                    if (sec_pulse) begin
                        if (sec_timer > 8'd0) begin
                            sec_timer <= sec_timer - 1'b1;
                        end else begin
                            // After (Cooling_Time)s change to PW_ENTER
                            current_state <= PW_ENTER;
                        end
                    end
                end

                default: current_state <= PW_SELECT;
            endcase
        end
    end
endmodule






module number_select_save(
    input clk, rst, start, //rst may need to be debounced
    input enter, next_digit, next_number, 
    output reg [3:0] digit1, digit2, digit3, digit4,
    output reg [3:0] save1, save2, save3, save4,
    output reg [3:0] led
);





//currently using digit 
reg [1:0] using_digit;

//register for save1,2,3,4
reg [3:0] r_save1, r_save2, r_save3, r_save4;


//wire and reg for connection 
wire [3:0] w_digit_number; //output number of using digit  
wire [3:0] w_next_saved; 
wire next_digit_p;

//next_digit debounce and generate pulse 
BTN_DEB next_digit_db(
    .clk(clk), 
    .rst(rst),
    .btn(next_digit),
    .btn_deb(next_digit_deb)
);
Pulse_GEN next_digit_pulse(
    .clk(clk), 
    .rst(rst),
    .in(next_digit_deb),
    .out(next_digit_p)
);
                      
//hope I don't mess it up >_< 
//botton logic
always @(posedge clk or posedge rst) begin
    
    if(rst||start)begin //clear all saved number and start inputting from digit1
        using_digit <= 2'd0;
        r_save1 <= 4'd0;
        r_save2 <= 4'd0;
        r_save3 <= 4'd0;
        r_save4 <= 4'd0;
        save1 <= 4'd0;
        save2 <= 4'd0;
        save3 <= 4'd0;
        save4 <= 4'd0;
    end 
    
    else if (enter) begin 
        case (using_digit) //save current using digit 
            2'd0: r_save1 <= w_digit_number;
            2'd1: r_save2 <= w_digit_number;
            2'd2: r_save3 <= w_digit_number;
            2'd3: r_save4 <= w_digit_number;
        endcase
        save1 <= (using_digit == 2'd0) ? w_digit_number : r_save1;
        save2 <= (using_digit == 2'd1) ? w_digit_number : r_save2;
        save3 <= (using_digit == 2'd2) ? w_digit_number : r_save3;
        save4 <= (using_digit == 2'd3) ? w_digit_number : r_save4;
    end
    else if (next_digit_p) begin //save current using digit and start input next digit
        case (using_digit)
            2'd0: begin r_save1<=w_digit_number; using_digit<=2'd1; end
            2'd1: begin r_save2<=w_digit_number; using_digit<=2'd2; end
            2'd2: begin r_save3<=w_digit_number; using_digit<=2'd3; end
            2'd3: begin r_save4<=w_digit_number; using_digit<=2'd0; end
        endcase
    end
     
end

//each using_digit logic
always @(*) begin
    
    case (using_digit)
        2'd0: begin
            digit1 = w_digit_number;
            digit2 = r_save2;
            digit3 = r_save3;
            digit4 = r_save4;
            led = 4'b0001;
            
        end 

        2'd1: begin
            digit1 = r_save1;
            digit2 = w_digit_number;
            digit3 = r_save3;
            digit4 = r_save4;
            led = 4'b0010;
            
        end

        2'd2: begin
            digit1 = r_save1;
            digit2 = r_save2;
            digit3 = w_digit_number;
            digit4 = r_save4;
            led = 4'b0100;
            
        end

        2'd3: begin
            digit1 = r_save1;
            digit2 = r_save2;
            digit3 = r_save3;
            digit4 = w_digit_number;
            led = 4'b1000;
            
        end
        
        default: begin
            digit1 = r_save1;
            digit2 = r_save2;
            digit3 = r_save3;
            digit4 = r_save4;
            led = 4'b0000;
            
        end
    endcase
end

//predict next input
assign w_next_saved = (using_digit == 2'd0) ? r_save2 :
                      (using_digit == 2'd1) ? r_save3 :
                      (using_digit == 2'd2) ? r_save4 : r_save1;
                      
//MC output the number
MC_TOP_mode4 mc4(
    .clk(clk), 
    .rst(rst | start),
    .btn(next_number),
    .current_digit_number(w_digit_number), 
    .next_digit(next_digit_p),
    .saved(w_next_saved)
);

endmodule




//MC -- only count up in 0~9
module MC_TOP_mode4 (
    input clk, rst, next_digit,
    input btn, //[1:0] btn,
    input [3:0] saved,
    output [3:0] current_digit_number
);

    BTN_DEB debounce_up(
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .btn_deb(btn_db_up)
    );
    Pulse_GEN pulseGEN_up(
        .clk(clk),
        .rst(rst),
        .in(btn_db_up),
        .out(up_pulse)
    );
    MC_mode4 MC(
        .clk(clk),
        .rst(rst),
        .up_pulse(up_pulse),
        .led(current_digit_number), 
        .next_digit(next_digit),
        .saved(saved)
    );
endmodule




module MC_mode4 (
    input clk, rst, 
    input up_pulse, next_digit,
    input [3:0] saved,
    output reg [3:0] led
);
always @ (posedge clk or posedge rst)begin
    if (rst) begin
        led <= 4'd0;                   
    end
    else if (next_digit) begin
        led <= saved;                  
    end
    else if (up_pulse && (led < 4'd9)) led <= led + 4'd1;
    else if (up_pulse && (led == 4'd9)) led <= 4'b0000; //restrict led to 0~9
    end
endmodule
