`timescale 1ns / 1ns

module counter #(
    parameter [24:0] CNT_MAX = 25'd24_999_999
) (
    input  wire sys_clk,
    input  wire sys_rst_n,
    output reg  led_out
);

reg [24:0] cnt;

// 50 MHz: 25,000,000 clock cycles = 0.5 s.
// The LED and reset button are active low.
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt     <= 25'd0;
        led_out <= 1'b0;
    end
    else if (cnt == CNT_MAX) begin
        cnt     <= 25'd0;
        led_out <= ~led_out;
    end
    else begin
        cnt <= cnt + 25'd1;
    end
end

endmodule
