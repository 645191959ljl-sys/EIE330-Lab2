`timescale 1ns / 1ns

module DevelopmentBoard (
    input wire clk,
    input wire reset, B2, B3, B4, B5,
    output wire h_sync, v_sync,
    output wire [15:0] rgb,
    output wire led1, led2, led3, led4, led5
);

// B3 tests the RTL reset; the simulator RESET key is not connected to it.
counter counter_inst (
    .sys_clk(clk),
    .sys_rst_n(B3),
    .led_out(led1)
);

assign led2 = 1'b1;
assign led3 = 1'b1;
assign led4 = 1'b1;
assign led5 = 1'b1;
assign h_sync = 1'b0;
assign v_sync = 1'b0;
assign rgb = 16'b0;

endmodule
