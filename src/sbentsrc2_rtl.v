module explicit_comparator #(
	parameter WIDTH=1
)(
	input wire [WIDTH-1:0] i_a,
	input wire [WIDTH-1:0] i_b,
	output reg o_match
); /* synthesis syn_preserve = 1 */
always @* o_match = i_a==i_b;
endmodule

module sbhdvar(
	input wire [4-1:0] i_dat,
	output reg [4-1:0] o_dat
); /* synthesis syn_preserve = 1 */
function [4-1:0] sbox_f;
    input [4-1:0] in;
    begin
        case(in)
        4'b0000: sbox_f = 4'b0011;//0->3, hd=2
        4'b0011: sbox_f = 4'b1100;//3->C, hd=4
        4'b1100: sbox_f = 4'b1010;//C->A, hd=2
        4'b1010: sbox_f = 4'b0001;//A->1, hd=3
        4'b0001: sbox_f = 4'b0110;//1->6, hd=3
        4'b0110: sbox_f = 4'b1001;//6->9, hd=4
        4'b1001: sbox_f = 4'b1000;//9->8, hd=1
        4'b1000: sbox_f = 4'b0101;//8->5, hd=3
        4'b0101: sbox_f = 4'b0100;//5->4, hd=1
        4'b0100: sbox_f = 4'b1101;//4->D, hd=2
        4'b1101: sbox_f = 4'b0010;//D->2, hd=4
        4'b0010: sbox_f = 4'b1111;//2->F, hd=3
        4'b1111: sbox_f = 4'b1110;//F->E, hd=1
        4'b1110: sbox_f = 4'b0111;//E->7, hd=2
        4'b0111: sbox_f = 4'b1011;//7->B, hd=2
        4'b1011: sbox_f = 4'b0000;//B->0, hd=3
        endcase
    end
endfunction
always @(*) #1000 o_dat = sbox_f(i_dat);
endmodule
module sbhdvar_inv(
	input wire [4-1:0] i_dat,
	output reg [4-1:0] o_dat
); /* synthesis syn_preserve = 1 */
function [4-1:0] sbox_f_inv;
    input [4-1:0] in;
    begin
        case(in)
        4'b0011: sbox_f_inv = 4'b0000;//3->0, hd=2
        4'b1100: sbox_f_inv = 4'b0011;//C->3, hd=4
        4'b1010: sbox_f_inv = 4'b1100;//A->C, hd=2
        4'b0001: sbox_f_inv = 4'b1010;//1->A, hd=3
        4'b0110: sbox_f_inv = 4'b0001;//6->1, hd=3
        4'b1001: sbox_f_inv = 4'b0110;//9->6, hd=4
        4'b1000: sbox_f_inv = 4'b1001;//8->9, hd=1
        4'b0101: sbox_f_inv = 4'b1000;//5->8, hd=3
        4'b0100: sbox_f_inv = 4'b0101;//4->5, hd=1
        4'b1101: sbox_f_inv = 4'b0100;//D->4, hd=2
        4'b0010: sbox_f_inv = 4'b1101;//2->D, hd=4
        4'b1111: sbox_f_inv = 4'b0010;//F->2, hd=3
        4'b1110: sbox_f_inv = 4'b1111;//E->F, hd=1
        4'b0111: sbox_f_inv = 4'b1110;//7->E, hd=2
        4'b1011: sbox_f_inv = 4'b0111;//B->7, hd=2
        4'b0000: sbox_f_inv = 4'b1011;//0->B, hd=3
        endcase
    end
endfunction
always @(*) #1000 o_dat = sbox_f_inv(i_dat);
endmodule

module sbhdvar_slice(
	input wire i_clk,
	input wire i_ff_reset,
	input wire i_reset_l1,
	input wire i_en,
	output reg [4-1:0] o_rnd
	); /* synthesis syn_preserve = 1 */

reg [4-1:0] in;
wire [4-1:0] out,check;
reg update;
wire match;
genvar tail_index;
generate

	explicit_comparator #(.WIDTH(4)) u_comparator_ITK (
		.i_a(in), 
		.i_b(check), 
		.o_match(match)
	);
	always @* begin: UPDATE
    	update = match & (i_en & ~i_reset_l1);
	end
  	always @(posedge update, posedge i_ff_reset) begin
		if(i_ff_reset) in <= {4{1'b0}};
		else in <= out;
  	end
	sbhdvar  	u_sb_ITK    (.i_dat(in), .o_dat(out));
	sbhdvar_inv  u_sb_inv_ITK(.i_dat(out), .o_dat(check));
endgenerate

wire [4-1:0] sampler_input_NTK = out ^ check;
always @(posedge i_clk, posedge i_ff_reset) begin: SAMPLER
	if(i_ff_reset) o_rnd <= {4{1'b0}};
	else o_rnd <= sampler_input_NTK;
end

endmodule

module sbentsrc #(
	parameter RNG_WIDTH = 4,
	parameter RESET = 1
	)(
	input wire i_clk,
	input wire i_reset,
	input wire i_en,
	output wire [RNG_WIDTH-1:0] o_rnd
	); /* synthesis syn_preserve = 1 */

wire ff_reset = RESET & i_reset;	
reg reset_l1;
always @(posedge i_clk) reset_l1 <= i_reset;
localparam NSBOXES = RNG_WIDTH / 4;
genvar sbox_index;
generate
for(sbox_index=0;sbox_index<NSBOXES;sbox_index=sbox_index+1) begin: SBOXES
	sbhdvar_slice slice_ITK (
		.i_clk(i_clk),
		.i_ff_reset(ff_reset),
		.i_reset_l1(reset_l1),
		.i_en(i_en),	
 		.o_rnd(o_rnd[sbox_index*4+:4])
	);
end

endgenerate

endmodule
