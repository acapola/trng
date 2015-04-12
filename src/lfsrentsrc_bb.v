
module lfsrentsrc #(
	parameter RNG_WIDTH = 32,
	parameter RESET = 1
	)(
	input wire i_clk,
	input wire i_reset,
	input wire i_en,
	output reg [RNG_WIDTH-1:0] o_rnd
	) /* synthesis syn_blackbox = 1 */ ;

endmodule