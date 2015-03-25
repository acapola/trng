
module frlfsr4 #(
    parameter SEED = 4'hB,
    parameter BITS_PER_CYCLE = 1//min is 1, max is 2
)(
	input wire i_reset,
	input wire i_en,
    output reg [4-1:0] o_rnd
);
function [3:0] lfsrFunc;
    input [3:0] in;
    integer i;
    reg [3:0] out;
    reg [3:0] tmp;
    begin
        tmp = in;
        for(i=0;i<BITS_PER_CYCLE;i=i+1) begin
            out[3] = tmp[0] ^ tmp[1];
            out[3-1:0] = tmp[3:1];
            tmp = out;
        end
        lfsrFunc = out;
    end
endfunction
wire deadlock = ~ (|o_rnd);
always @* begin: COMBO_LOOP_BLOCK //intended combinational loop
    if(i_reset) o_rnd = SEED;
	else if(i_en) begin
		o_rnd = deadlock ? SEED : lfsrFunc(o_rnd);
    end
end
endmodule


module lfsrentsrc #(
	parameter RNG_WIDTH = 4,
	parameter RESET = 1
	)(
	input wire i_clk,
	input wire i_reset,
	input wire i_en,
	output reg [RNG_WIDTH-1:0] o_rnd
	) /* synthesis syn_preserve = 1 */ ;

wire ff_reset = RESET & i_reset;	

wire [RNG_WIDTH-1:0] out;
localparam NSTAGES = RNG_WIDTH/4;

genvar stage_index;
generate
for(stage_index=0;stage_index<NSTAGES;stage_index=stage_index+1) begin: IN
	frlfsr4 u_frlsfr4(
		.i_reset(i_reset),
		.i_en(i_en),
		.o_rnd(out[stage_index*4+:4])
	);
end
endgenerate

always @(posedge i_clk, posedge ff_reset) begin: SAMPLER
	if(ff_reset) o_rnd <= {RNG_WIDTH{1'b0}};
	else o_rnd <= out;
end

endmodule