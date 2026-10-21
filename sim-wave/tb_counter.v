`timescale 1ns / 1ns

module tb_counter;

reg sys_clk;
reg sys_rst_n;
wire led_out;
integer checks;
integer i;
reg expected_led;

// Shortened count: 8 cycles per LED change, still using a 50 MHz clock.
counter #(.CNT_MAX(25'd7)) dut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .led_out(led_out)
);

initial sys_clk = 1'b0;
always #10 sys_clk = ~sys_clk;

task check_state;
    input [24:0] expected_cnt;
    input expected_out;
    begin
        checks = checks + 1;
        if ((dut.cnt !== expected_cnt) || (led_out !== expected_out)) begin
            $display("FAIL t=%0t: cnt=%0d expected=%0d led=%b expected=%b",
                     $time, dut.cnt, expected_cnt, led_out, expected_out);
            $fatal(1, "State mismatch");
        end
    end
endtask

// Starts with cnt=0 and checks every rising edge of one full half-period.
task check_half_period;
    begin
        for (i = 1; i <= 8; i = i + 1) begin
            @(posedge sys_clk);
            #1; // Observe after nonblocking assignments settle.
            if (i < 8)
                check_state(i, expected_led);
            else begin
                expected_led = ~expected_led;
                check_state(25'd0, expected_led);
            end
        end
    end
endtask

initial begin
    checks = 0;
    expected_led = 1'b0;
    sys_rst_n = 1'b1;
    $dumpfile("sim-wave/tb_counter.vcd");
    $dumpvars(0, tb_counter);
    $timeformat(-9, 0, " ns", 8);
    $monitor("t=%t rst_n=%b cnt=%0d led_out=%b",
             $time, sys_rst_n, dut.cnt, led_out);

    // Initial asynchronous reset at t=3 ns (no clock edge).
    #3 sys_rst_n = 1'b0;
    #1 check_state(25'd0, 1'b0);
    // Keep reset asserted across a rising edge; release at t=27 ns.
    #23 sys_rst_n = 1'b1;
    check_half_period; // LED off after 8 edges.
    check_half_period; // LED on after another 8 edges.
    check_half_period; // LED off again: consecutive changes are 160 ns apart.

    // Reset mid-count while LED is off, between rising edges.
    repeat (3) @(posedge sys_clk);
    #1 check_state(25'd3, 1'b1);
    #2 sys_rst_n = 1'b0;
    #1 check_state(25'd0, 1'b0); // Must not wait for the next clock.
    repeat (3) begin
        @(posedge sys_clk);
        #1 check_state(25'd0, 1'b0); // Holding reset freezes initial state.
    end
    @(negedge sys_clk);
    #3 sys_rst_n = 1'b1;
    expected_led = 1'b0;
    check_half_period; // Full count restarts, no leftover partial count.
    check_half_period;

    // Also reset mid-count while LED is already on.
    repeat (5) @(posedge sys_clk);
    #1 check_state(25'd5, 1'b0);
    #2 sys_rst_n = 1'b0;
    #1 check_state(25'd0, 1'b0);
    @(negedge sys_clk);
    #3 sys_rst_n = 1'b1;
    expected_led = 1'b0;
    check_half_period;
    check_half_period;
    $display("PASS: %0d state checks; 20 ns clock, 8-cycle interval, asynchronous reset and restart.", checks);
    $finish;
end

// Watchdog: a broken clock/test sequence must not silently hang.
initial begin
    #3000;
    $fatal(1, "Test timed out");
end

endmodule
