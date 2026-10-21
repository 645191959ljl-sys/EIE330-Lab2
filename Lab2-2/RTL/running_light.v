`timescale 1ns / 1ns

module running_light #(
    parameter [24:0] CNT_MAX = 25'd24_999_999
) (
    input wire sys_clk,
    input wire sys_rst_n,
    output reg [3:0] led_out
);

reg [24:0] cnt;

// Active-low LEDs: LED0 is initially on. One step every 0.5 s at 50 MHz.
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt <= 25'd0;
        led_out <= 4'b1110;
    end
    else if (cnt == CNT_MAX) begin
        cnt <= 25'd0;
        led_out <= {led_out[2:0], led_out[3]};
    end
    else begin
        cnt <= cnt + 25'd1;
    end
end

endmodule
