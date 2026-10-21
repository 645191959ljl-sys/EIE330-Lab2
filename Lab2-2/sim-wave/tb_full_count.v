`timescale 1ns / 1ns

module tb_full_count;
reg sys_clk = 1'b0;
reg sys_rst_n = 1'b1;
wire [3:0] led_out;
running_light dut(.sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .led_out(led_out));
always #10 sys_clk = ~sys_clk;
initial begin
    #3 sys_rst_n = 1'b0;
    #24 sys_rst_n = 1'b1;
    repeat (24_999_999) @(posedge sys_clk);
    #1;
    if (dut.cnt !== 25'd24_999_999 || led_out !== 4'b1110)
        $fatal(1, "Early transition or incorrect terminal count");
    @(posedge sys_clk); #1;
    if (dut.cnt !== 25'd0 || led_out !== 4'b1101)
        $fatal(1, "First full-count step failed");
    $display("First step: t=%0t ns; 25,000,000 rising edges; cnt=0; led=1101", $time);
    repeat (25_000_000) @(posedge sys_clk);
    #1;
    if (dut.cnt !== 25'd0 || led_out !== 4'b1011)
        $fatal(1, "Second full-count step failed");
    $display("PASS: second step t=%0t ns; interval=500000000 ns=0.5 s; default CNT_MAX=24999999.", $time);
    $finish;
end
endmodule
