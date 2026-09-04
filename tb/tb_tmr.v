`timescale 1ns/1ps
module tb_tmr;
  localparam W = 8;
  reg clk = 0, rst = 1;
  reg [W-1:0] d = 0;
  reg [3*W-1:0] inject = 0;
  wire [W-1:0] q; wire fault_seen;
  integer errors = 0;

  tmr_reg #(W) dut (.clk(clk), .rst(rst), .d(d), .inject(inject), .q(q), .fault_seen(fault_seen));
  always #5 clk = ~clk;

  task step; begin @(posedge clk); #1; end endtask
  task check(input [W-1:0] exp, input [511:0] name);
    begin
      if (q !== exp) begin
        $display("FAIL %0s: q=%b expected %b", name, q, exp); errors = errors + 1;
      end else $display("ok   %0s: q=%b fault_seen=%b", name, q, fault_seen);
    end
  endtask

  initial begin
    step; rst = 0;
    d = 8'hA5; inject = 0;              step; check(8'hA5, "golden, no fault");
    inject = {8'h00, 8'h00, 8'h01};     step; check(8'hA5, "1 bit flipped in copy0 - masked");
    inject = {8'h00, 8'h80, 8'h01};     step; check(8'hA5, "1 bit each in 2 copies, diff positions - masked");
    inject = {8'h00, 8'h01, 8'h01};     step; check(8'hA4, "SAME bit in 2 copies - TMR defeated (expected)");
    inject = 0;                         step; check(8'hA5, "recovered");
    if (errors == 0) $display("\nTMR saboteur smoke test PASSED");
    else             $display("\nTMR saboteur smoke test FAILED (%0d)", errors);
    $finish;
  end
endmodule
