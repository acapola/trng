module ring_stage_basic(
	input wire i_f,
	input wire i_r,
	output reg o_c
	);
always @* begin
	if( i_f & ~i_r) o_c = 1'b1;
	if(~i_f &  i_r) o_c = 1'b0;
end	
endmodule

module async_ring1 #(
	parameter WIDTH = 5,
	parameter INIT_VALUE = 5'b01010
	)(
	input wire i_reset,
	output reg [WIDTH-1:0] o_dat
	);
	
reg [WIDTH-1:0] f;
reg [WIDTH-1:0] r;	
wire [WIDTH-1:0] c;	
always @* o_dat = i_reset ? INIT_VALUE : c;
genvar i;
generate
	for(i=0;i<WIDTH;i=i+1) begin: STAGE
		ring_stage stage(.i_f(f[i]), .i_r(r[i]), .o_c(c[i]));
		always @* f[i] = o_dat[(i+WIDTH-1)%WIDTH];
		always @* r[i] = o_dat[(i+1)%WIDTH];
	end
endgenerate
endmodule

module ring_stage(
	input wire i_reset,
	input wire i_init_val,
	input wire i_f,
	input wire i_r,
	output wire o_c
	);
	ring_stage_impl impl(.i_reset(i_reset), .i_init_val(i_init_val), .i_f(i_f), .i_r(i_r), .o_c(o_c));
endmodule

module ring_stage_rtl(
	input wire i_reset,
	input wire i_init_val,
	input wire i_f,
	input wire i_r,
	output reg o_c
	);
always @* begin
	if(i_reset) o_c = i_init_val;
	else begin
		if(      i_f & ~i_r) o_c = 1'b1;
		else if(~i_f &  i_r) o_c = 1'b0;
	end
end	
endmodule

module async_ring #(
	parameter WIDTH = 5
	)(
	input wire i_reset,
	input wire [WIDTH-1:0] i_init_val,
	output wire [WIDTH-1:0] o_dat
	);
	
reg [WIDTH-1:0] f;
reg [WIDTH-1:0] r;	
genvar i;
generate
	for(i=0;i<WIDTH;i=i+1) begin: STAGE
		ring_stage stage(.i_reset(i_reset), .i_init_val(i_init_val[i]), .i_f(f[i]), .i_r(r[i]), .o_c(o_dat[i]));
		always @* f[i] = o_dat[(i+WIDTH-1)%WIDTH];
		always @* r[i] = o_dat[(i+1)%WIDTH];
	end
endgenerate
endmodule

module entropy_extractor #(
	parameter WIDTH = 5
	)(
	input wire i_clk,
	input wire [WIDTH-1:0] i_rnd_src,
	output reg [WIDTH-1:0] o_sampled,//to avoid automatic optimization and allow testing
	output reg o_rnd
);
always @(posedge i_clk) o_sampled <= i_rnd_src;
always @(posedge i_clk) o_rnd <= ^o_sampled;
endmodule

///// BLACK BOX DECLARATION /////
module async_ring_ice40_loc #(
	parameter WIDTH = 7
	)(
	input wire i_reset,
	input wire i_clk,
	input wire [WIDTH-1:0] i_init_val,
	output reg [WIDTH-1:0] o_dat
	)/* synthesis syn_blackbox = 1 */ ;
endmodule

module async_trng #(
	parameter WIDTH = 8,//max is 255
	parameter NSRC = 1,//number of rings running in parallel
	parameter SRC_WIDTH = 5//size of each ring
	)(
	input wire i_reset,
	input wire [SRC_WIDTH-1:0] i_src_init_val,
	input wire i_clk,
	input wire i_read,
	output reg [WIDTH-1:0] o_dat,
	output reg o_valid,
	output wire [NSRC*SRC_WIDTH-1:0] o_sampled
);
wire raw_rnd;
wire [NSRC*SRC_WIDTH-1:0] rnd_src_dat;
genvar i;
generate
	for(i=0;i<NSRC;i=i+1) begin: RING
		async_ring #(.WIDTH(SRC_WIDTH)) rnd_src (.i_reset(i_reset), .i_init_val(i_src_init_val), .o_dat(rnd_src_dat[i*SRC_WIDTH+:SRC_WIDTH]));
	end
endgenerate
entropy_extractor #(.WIDTH(NSRC*SRC_WIDTH)) extractor (.i_clk(i_clk), .i_rnd_src(rnd_src_dat),
	.o_sampled(o_sampled), .o_rnd(raw_rnd));
localparam CNT_WIDTH = 8;
reg [CNT_WIDTH-1:0] cnt;	
always @(posedge i_clk) begin
	if(i_reset) begin
		cnt <= {CNT_WIDTH{1'b0}};
		o_dat <= {WIDTH{1'b0}};
	end else begin
		if(i_read & o_valid) begin
			cnt <= {CNT_WIDTH{1'b0}};
			o_dat <= {{WIDTH-1{1'b0}},raw_rnd};//start a new output byte, keep them independent
		end else begin
			o_dat <= {o_dat[0+:WIDTH-1],o_dat[WIDTH-1]^raw_rnd};//the xor gather entropy in case the data is not consumed immediately
			if(~o_valid) cnt <= cnt + 1'b1;
		end
	end
end
always @* o_valid = cnt==WIDTH;
endmodule
	