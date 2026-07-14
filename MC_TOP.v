`timescale 1ns / 1ps

module MC_TOP (
    input clk, rst,
    input [1:0] btn,
    output [3:0] led
);

    BTN_DEB debounce_up(
        .clk(clk),
        .rst(rst),
        .btn(btn[1]),
        .btn_deb(btn_db_up)
    );
    Pulse_GEN pulseGEN_up(
        .clk(clk),
        .rst(rst),
        .in(btn_db_up),
        .out(up_pulse)
    );
    BTN_DEB debounce_down(
        .clk(clk),
        .rst(rst),
        .btn(btn[0]),
        .btn_deb(btn_db_down)
    );
    Pulse_GEN pulseGEN_down(
        .clk(clk),
        .rst(rst),
        .in(btn_db_down),
        .out(down_pulse)
    );
    MC MC(
        .clk(clk),
        .rst(rst),
        .up_pulse(up_pulse),
        .down_pulse(down_pulse),
        .led(led)
    );
endmodule

module BTN_DEB (
    input clk, rst,
    input btn,
    output reg btn_deb
); 
    
    parameter COUNT_50MS = 625000; //625000 //test
    reg [22:0] counter;
    reg [1:0] state, next_state;

    parameter STABLE0  = 2'b00;
    parameter UNSTABLE = 2'b01;
    parameter STABLE1  = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= STABLE0;
        else state <= next_state;
    end

    always @(*) begin
        case (state)
            STABLE0:  next_state = (btn == 1'b1) ? UNSTABLE : STABLE0;
            UNSTABLE: begin
                if (btn == btn_deb) next_state = (btn_deb ? STABLE1 : STABLE0);
                else if (counter >= COUNT_50MS) next_state = (btn ? STABLE1 : STABLE0);
                else next_state = UNSTABLE;
            end
            STABLE1:  next_state = (btn == 1'b0) ? UNSTABLE : STABLE1;
            default: next_state = STABLE0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            btn_deb <= 0;
        end else if (state == UNSTABLE) begin
            counter <= counter + 1;
            if (counter >= COUNT_50MS) begin
                btn_deb <= ~btn_deb;
                counter <= 0;
            end
        end else begin
            counter <= 0;
        end
    end

endmodule

module Pulse_GEN (
    input clk, rst,
    input in,
    output out
);

    reg in_delay;

    assign out = in & (~in_delay);

    always @(posedge clk or posedge rst) begin
        if (rst) in_delay <= 1'b0;
        else in_delay <= in;
    end
endmodule

module MC (
    input clk, rst,
    input up_pulse, down_pulse,
    output reg [3:0] led
);
    always @(posedge clk or posedge rst) begin
        if (rst) led <= 4'b0001;
        else if (up_pulse) led <= led + 1'b1;
        else if (down_pulse) led <= led - 1'b1;
    end
    
endmodule

