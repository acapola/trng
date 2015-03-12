
module sbentsrc #(
	parameter RNG_WIDTH = 4,
	parameter RESET = 1
	)(
	input wire i_clk,
	input wire i_reset,
	input wire i_en,
	output reg [RNG_WIDTH-1:0] o_rnd
	) /* synthesis syn_preserve = 1 */ ;

wire ff_reset = RESET & i_reset;	
	
function [3:0] sbox_f_min_hd2;
//design criterias:
//- invertible
//- out->in sequence visit all states
//- hamming distance between two consecutive states >=2 
    input [3:0] in;
    begin
        case(in)
        4'b0000: sbox_f_min_hd2 = 4'b0011;//0->3, hd=2
        4'b0011: sbox_f_min_hd2 = 4'b1100;//3->C, hd=4
        4'b1100: sbox_f_min_hd2 = 4'b1010;//C->A, hd=2
        4'b1010: sbox_f_min_hd2 = 4'b0001;//A->1, hd=3
        4'b0001: sbox_f_min_hd2 = 4'b0110;//1->6, hd=3
        4'b0110: sbox_f_min_hd2 = 4'b1111;//6->F, hd=2
        4'b1111: sbox_f_min_hd2 = 4'b0101;//F->5, hd=2
        4'b0101: sbox_f_min_hd2 = 4'b1000;//5->8, hd=3
        4'b1000: sbox_f_min_hd2 = 4'b1011;//8->B, hd=2
        4'b1011: sbox_f_min_hd2 = 4'b1101;//B->D, hd=2
        4'b1101: sbox_f_min_hd2 = 4'b0111;//D->7, hd=2
        4'b0111: sbox_f_min_hd2 = 4'b0010;//7->2, hd=2
        4'b0010: sbox_f_min_hd2 = 4'b1001;//2->9, hd=3
        4'b1001: sbox_f_min_hd2 = 4'b0100;//9->4, hd=3
        4'b0100: sbox_f_min_hd2 = 4'b1110;//4->E, hd=2
        4'b1110: sbox_f_min_hd2 = 4'b0000;//E->0, hd=3   
        endcase
    end
endfunction

function [3:0] inv_sbox_f_min_hd2;
    input [3:0] in;
    begin
        case(in)

        4'b0011: inv_sbox_f_min_hd2 = 4'b0000;//3->0, hd=2
        4'b1100: inv_sbox_f_min_hd2 = 4'b0011;//C->3, hd=4
        4'b1010: inv_sbox_f_min_hd2 = 4'b1100;//A->C, hd=2
        4'b0001: inv_sbox_f_min_hd2 = 4'b1010;//1->A, hd=3
        4'b0110: inv_sbox_f_min_hd2 = 4'b0001;//6->1, hd=3
        4'b1111: inv_sbox_f_min_hd2 = 4'b0110;//F->6, hd=2
        4'b0101: inv_sbox_f_min_hd2 = 4'b1111;//5->F, hd=2
        4'b1000: inv_sbox_f_min_hd2 = 4'b0101;//8->5, hd=3
        4'b1011: inv_sbox_f_min_hd2 = 4'b1000;//B->8, hd=2
        4'b1101: inv_sbox_f_min_hd2 = 4'b1011;//D->B, hd=2
        4'b0111: inv_sbox_f_min_hd2 = 4'b1101;//7->D, hd=2
        4'b0010: inv_sbox_f_min_hd2 = 4'b0111;//2->7, hd=2
        4'b1001: inv_sbox_f_min_hd2 = 4'b0010;//9->2, hd=3
        4'b0100: inv_sbox_f_min_hd2 = 4'b1001;//4->9, hd=3
        4'b1110: inv_sbox_f_min_hd2 = 4'b0100;//E->4, hd=2
        4'b0000: inv_sbox_f_min_hd2 = 4'b1110;//0->E, hd=3   

        endcase
    end
endfunction

function [3:0] sbox_f_hd3;
//design criterias:
//- invertible
//- out->in sequence visit all states
//- hamming distance between two consecutive states >=3 
    input [3:0] in;
    begin
        case(in)
		4'b0000: sbox_f_hd3 = 4'b1110;//0->E, hd=3
        4'b1110: sbox_f_hd3 = 4'b0011;//E->3, hd=3
        4'b0011: sbox_f_hd3 = 4'b1101;//3->D, hd=3
        4'b1101: sbox_f_hd3 = 4'b0110;//D->6, hd=3
        4'b0110: sbox_f_hd3 = 4'b1000;//6->8, hd=3
        4'b1000: sbox_f_hd3 = 4'b0101;//8->5, hd=3
        4'b0101: sbox_f_hd3 = 4'b1011;//5->B, hd=3
        4'b1011: sbox_f_hd3 = 4'b1100;//B->C, hd=3
        4'b1100: sbox_f_hd3 = 4'b0010;//C->2, hd=3
        4'b0010: sbox_f_hd3 = 4'b1111;//2->F, hd=3
        4'b1111: sbox_f_hd3 = 4'b0001;//F->1, hd=3
        4'b0001: sbox_f_hd3 = 4'b1010;//1->A, hd=3
        4'b1010: sbox_f_hd3 = 4'b0100;//A->4, hd=3
        4'b0100: sbox_f_hd3 = 4'b1001;//4->9, hd=3
        4'b1001: sbox_f_hd3 = 4'b0111;//9->7, hd=3
		4'b0111: sbox_f_hd3 = 4'b0000;//7->0, hd=3
        endcase
    end
endfunction

function [3:0] inv_sbox_f_hd3;
    input [3:0] in;
    begin
        case(in)
		4'b1110: inv_sbox_f_hd3 = 4'b0000;//E->0, hd=3
        4'b0011: inv_sbox_f_hd3 = 4'b1110;//3->E, hd=3
        4'b1101: inv_sbox_f_hd3 = 4'b0011;//D->3, hd=3
        4'b0110: inv_sbox_f_hd3 = 4'b1101;//6->D, hd=3
        4'b1000: inv_sbox_f_hd3 = 4'b0110;//8->6, hd=3
        4'b0101: inv_sbox_f_hd3 = 4'b1000;//5->8, hd=3
        4'b1011: inv_sbox_f_hd3 = 4'b0101;//B->5, hd=3
        4'b1100: inv_sbox_f_hd3 = 4'b1011;//C->B, hd=3
        4'b0010: inv_sbox_f_hd3 = 4'b1100;//2->C, hd=3
        4'b1111: inv_sbox_f_hd3 = 4'b0010;//F->2, hd=3
        4'b0001: inv_sbox_f_hd3 = 4'b1111;//1->F, hd=3
        4'b1010: inv_sbox_f_hd3 = 4'b0001;//A->1, hd=3
        4'b0100: inv_sbox_f_hd3 = 4'b1010;//4->A, hd=3
        4'b1001: inv_sbox_f_hd3 = 4'b0100;//9->4, hd=3
        4'b0111: inv_sbox_f_hd3 = 4'b1001;//7->9, hd=3
		4'b0000: inv_sbox_f_hd3 = 4'b0111;//0->7, hd=3
        endcase
    end
endfunction

function [3:0] sbox_f;
    input [3:0] in;
    begin
        sbox_f = sbox_f_min_hd2(in);
    end
endfunction

function [3:0] inv_sbox_f;
    input [3:0] in;
    begin
        inv_sbox_f = inv_sbox_f_min_hd2(in);
    end
endfunction

reg [RNG_WIDTH-1:0] in,out,check;
localparam NSBOXES = RNG_WIDTH/4;
reg [NSBOXES-1:0] match;
//wire [NSBOXES-1:0] #250 delayed_match = match;//needed for simulation purposes
always @* begin: MATCH
    integer i;
	for(i=0;i<NSBOXES;i=i+1) begin
		#250 match[i] = (in[i*4+:4]==check[i*4+:4]) & ~match[i] & i_en & ~i_reset;//combinational loop here is intentional, we need it to start the operations
	end
end

genvar sbox_index;
generate
for(sbox_index=0;sbox_index<NSBOXES;sbox_index=sbox_index+1) begin: IN
  always @(posedge match[sbox_index], posedge ff_reset) begin
	if(ff_reset) in[sbox_index*4+:4] <= {4{1'b0}};
	else in[sbox_index*4+:4] <= out[sbox_index*4+:4];
  end
end
endgenerate

always @* begin: OUT
    integer i;
	for(i=0;i<NSBOXES;i=i+1) begin
		#1000 out[i*4+:4] = sbox_f(in[i*4+:4]);
	end
end

always @* begin: CHECK_REG
    integer i;
	for(i=0;i<NSBOXES;i=i+1) begin
		#1000 check[i*4+:4] = inv_sbox_f(out[i*4+:4]);
	end
end

always @(posedge i_clk, posedge ff_reset) begin: SAMPLER
	if(ff_reset) o_rnd <= {RNG_WIDTH{1'b0}};
	else o_rnd <= out ^ check;
end

endmodule