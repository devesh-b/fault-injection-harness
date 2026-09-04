// Triple-modular-redundant register with a per-copy bit-flip saboteur port.
//
// `inject` XORs into each redundant copy independently, so a testbench can flip
// any bit of any copy on any cycle and observe what the voter does about it.
// This is the injection primitive a fault campaign is built from: the voter
// masks a fault in one copy, and fails when two copies are hit in the SAME bit
// position -- which the testbench demonstrates rather than assumes.
`timescale 1ns/1ps
module tmr_reg #(parameter W = 8) (
  input              clk,
  input              rst,
  input      [W-1:0] d,
  input      [3*W-1:0] inject,   // saboteur: {inj2, inj1, inj0}
  output     [W-1:0] q,
  output             fault_seen  // voter disagreement flag
);
  reg [W-1:0] c0, c1, c2;
  always @(posedge clk) begin
    if (rst) begin c0 <= 0; c1 <= 0; c2 <= 0; end
    else begin
      c0 <= d ^ inject[0*W +: W];
      c1 <= d ^ inject[1*W +: W];
      c2 <= d ^ inject[2*W +: W];
    end
  end
  assign q = (c0 & c1) | (c1 & c2) | (c0 & c2);          // bitwise majority vote
  assign fault_seen = |((c0 ^ c1) | (c1 ^ c2));
endmodule
