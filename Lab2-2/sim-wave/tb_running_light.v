`timescale 1ns / 1ns

module tb_running_light;
reg sys_clk = 1'b0;
reg sys_rst_n = 1'b1;
wire [3:0] led_out;
integer checks = 0;
integer cycle;
integer phase;
integer expected_count = 0;
reg [3:0] expected_led = 4'b1110;

running_light #(.CNT_MAX(25'd7)) dut (
    .sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .led_out(led_out)
);
always #10 sys_clk = ~sys_clk;

task check_state;
    input [24:0] count;
    input [3:0] leds;
    begin
        checks = checks + 1;
        if (dut.cnt !== count || led_out !== leds)
            $fatal(1, "FAIL t=%0t cnt=%0d expected=%0d leds=%b expected=%b",
                   $time, dut.cnt, count, led_out, leds);
        if (!(led_out == 4'b1110 || led_out == 4'b1101 ||
              led_out == 4'b1011 || led_out == 4'b0111))
            $fatal(1, "Exactly one LED must be on");
    end
endtask

task run_cycles;
    input integer number;
    integer j;
    begin
        for (j = 0; j < number; j = j + 1) begin
            @(posedge sys_clk);
            if (expected_count == 7) begin
                expected_count = 0;
                case (expected_led)
                    4'b1110: expected_led = 4'b1101;
                    4'b1101: expected_led = 4'b1011;
                    4'b1011: expected_led = 4'b0111;
                    4'b0111: expected_led = 4'b1110;
                endcase
            end
            else expected_count = expected_count + 1;
            #1 check_state(expected_count, expected_led);
        end
    end
endtask

task reset_mid_count;
    begin
        // Called 1 ns after a rising edge; reset at +3 ns, between edges.
        #2 sys_rst_n = 1'b0;
        expected_count = 0;
        expected_led = 4'b1110;
        #1 check_state(25'd0, 4'b1110);
        repeat (3) begin
            @(posedge sys_clk);
            #1 check_state(25'd0, 4'b1110);
        end
        @(negedge sys_clk);
        #3 sys_rst_n = 1'b1;
    end
endtask

initial begin
    $dumpfile("sim-wave/tb_running_light.vcd");
    $dumpvars(0, tb_running_light);
    #3 sys_rst_n = 1'b0;
    #1 check_state(25'd0, 4'b1110);
    #23 sys_rst_n = 1'b1;
    run_cycles(72); // Two full wraps and another LED transition.
    reset_mid_count;
    for (phase = 0; phase < 4; phase = phase + 1) begin
        run_cycles(phase * 8 + 3); // Reset from every LED at cnt=3.
        reset_mid_count;
        run_cycles(8); // The next transition requires the full fresh interval.
        reset_mid_count;
    end
    run_cycles(64);
    $display("PASS: %0d checks; all four LEDs, wrap-around, asynchronous reset in every phase, held reset and restart.", checks);
    $finish;
end

initial begin
    #20000;
    $fatal(1, "Watchdog timeout");
end
endmodule
