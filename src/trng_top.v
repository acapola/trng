
`default_nettype none
module trng_top(
	input wire i_reset,
	input wire i_clk,
	//input wire i_serial_data,
	input wire i_serial_rts_n,
	output wire o_serial_data,
	output reg [3:0] o_dat_cnt/*,
//	output reg [7:0] o_spy_a,
//	output reg [7:0] o_spy_b,
//	output reg [7:0] o_spy_c*/
    );

localparam TRNG_NSRC = 4;
localparam TRNG_SRC_WIDTH = 7;
localparam TRNG_SRC_INIT = 7'b1001010;
localparam TRNG_OUT_WIDTH = 8;

reg trng_reset;
wire com_ready;	
wire trng_valid;
wire trng_read = trng_valid;
wire [7:0] trng_dat;
wire com_new_frame;
reg send;
reg [7:0] to_send;
wire [7:0] fifo_out;
reg ram_valid;
reg fifo_read_l1;
wire fifo_read = com_ready & ram_valid & ~fifo_read_l1;//read only when we have filled the fifo and com do a read
always @(posedge i_clk) begin
	if(i_reset) begin
		send <= 1'b0;
		fifo_read_l1 <= 1'b0;
	end else begin
		if(fifo_read_l1) begin
			fifo_read_l1 <= 1'b0;
			send <= 1'b1;
			to_send <= fifo_out;
		end else if(fifo_read) begin
			fifo_read_l1 <= 1'b1;
		end else send <= 1'b0;
	end
end

trng_com u_trng_com(
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_dat(to_send),
	.i_write(send),
	.i_serial_rts_n(i_serial_rts_n),
	.o_ready(com_ready),
	.o_serial_data(o_serial_data),
	.o_new_frame(com_new_frame)
	);
	
always @(posedge i_clk) begin
	if(i_reset) o_dat_cnt <= 4'h0;
	else if(com_new_frame) o_dat_cnt <= o_dat_cnt + 1'b1;	
end

reg [15:0] periodic_reset_cnt;
wire fifo_emptied = (~ram_valid) & fifo_read_l1;//single cycle pulse
wire periodic_reset = fifo_emptied & (periodic_reset_cnt==1);
reg periodic_reset_l1;
always @(posedge i_clk) periodic_reset_l1 <= periodic_reset;//register to have at least one full clock cycle to reset the trng
always @(posedge i_clk) begin
	if(i_reset | periodic_reset) periodic_reset_cnt <= {{15{1'b0}},1'b1};
	else if(fifo_emptied) periodic_reset_cnt <= periodic_reset_cnt + 1'b1;	
end
reg fifo_write;
always @(posedge i_clk) fifo_write <= ~ram_valid & ~periodic_reset & trng_valid;//fifo_write remains high for 1 cycle more than needed but fifo ignore it so no data is overwritten
always @* trng_reset = i_reset | periodic_reset_l1;

wire [TRNG_NSRC*TRNG_SRC_WIDTH-1:0] trng_sampled;
wire [TRNG_NSRC*TRNG_SRC_WIDTH-1:0] fake_trng_sampled;
/*reg [6:0] spy_a,spy_b,spy_c;
always @(posedge i_clk) spy_a <= i_reset ? fake_trng_sampled[0*7+:7] : trng_sampled[0*7+:7];
always @(posedge i_clk) spy_b <= i_reset ? fake_trng_sampled[1*7+:7] : trng_sampled[1*7+:7];
always @(posedge i_clk) spy_c <= i_reset ? fake_trng_sampled[2*7+:7] : trng_sampled[2*7+:7];
reg ext_clk0,ext_clk1;
always @(posedge i_clk) ext_clk0 <= ~ext_clk0;
always @(posedge i_clk) ext_clk1 <= ext_clk0;
always @* o_spy_a = {ext_clk0,spy_a};
always @* o_spy_b = {i_reset,spy_b};
always @* o_spy_c = {ext_clk1,spy_c};*/

async_trng trng (
	.i_reset(trng_reset),
	.i_src_init_val(TRNG_SRC_INIT),
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(trng_dat),
	.o_valid(trng_valid),
	.o_sampled(trng_sampled)
);
fake_trng #(.WIDTH(TRNG_OUT_WIDTH),.NSRC(TRNG_NSRC), .SRC_WIDTH(TRNG_SRC_WIDTH)) u_fake_trng (
	.i_reset(1'b0),//we output o_sampled only during reset time...
	.i_src_init_val(TRNG_SRC_INIT),
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(),
	.o_valid(),
	.o_sampled(fake_trng_sampled)
);



localparam FIFO_IN_WIDTH_BYTES = 1;
localparam FIFO_DEPTH_WIDTH = 14;
//we store sampled data in ram until its full and then dump the full memory
reg [FIFO_IN_WIDTH_BYTES*8-1:0] fifo_in;
always @(posedge i_clk) fifo_in <= trng_dat[FIFO_IN_WIDTH_BYTES*8-1:0];//pipeline reg because fifo_write is delayed as well
wire fifo_empty,fifo_full;
fifo #(
	.DEPTH_WIDTH(FIFO_DEPTH_WIDTH)//16384 bytes FIFO
	) u_fifo (
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_write(fifo_write),
	.i_read(fifo_read),
	.i_dat(fifo_in),
	.o_dat(fifo_out),
	.o_almost_empty(fifo_empty),
	.o_full(fifo_full)
	);
always @(posedge i_clk) begin
	if(i_reset) begin
		ram_valid <= 1'b0;//0 when we fill the fifo, 1 when we empty it
	end else begin
		if(ram_valid) begin //we read the fifo, once per com byte
			if(fifo_read) begin
				ram_valid <= ~fifo_empty;
			end
		end else begin//we fill the fifo, once per clock
			ram_valid <= fifo_full;
		end
	end
end

endmodule
module fifo #(
	parameter DEPTH_WIDTH = 10,
	//fixed parameters
	parameter OUT_WIDTH = 8,
	parameter IN_WIDTH = 8
	)(
	input wire i_reset,
	input wire i_clk,
	input wire i_write,
	input wire i_read,
	input wire [IN_WIDTH-1:0] i_dat,
	output reg [OUT_WIDTH-1:0] o_dat,
	output reg o_almost_empty,//can read one more time
	output reg o_empty,//cant read
	output reg o_almost_full,//can write one more time
	output reg o_full//can't write
	);
localparam DEPTH = 1 << DEPTH_WIDTH;
//assume a RAM for implementation of storage => don't use shift reg structure, use addresses	
reg [IN_WIDTH-1:0] storage[DEPTH-1:0];
reg [DEPTH_WIDTH-1:0] write_addr;
reg [DEPTH_WIDTH-1:0] read_addr;
wire [DEPTH_WIDTH-1:0] next_write_addr = write_addr + 1'b1;
wire [DEPTH_WIDTH-1:0] next_read_addr = read_addr + 1'b1;
always @* o_almost_empty = next_read_addr == write_addr;
always @* o_almost_full = next_write_addr == read_addr;
always @(posedge i_clk) begin
	if(i_reset) begin
		o_full <= 1'b0;
		o_empty <= 1'b1;
		write_addr <= {DEPTH_WIDTH{1'b0}};
		read_addr <= {DEPTH_WIDTH{1'b0}};
	end else begin
		if(i_write & ~o_full) begin
			o_empty <= 1'b0;
			o_full <= o_almost_full;
			write_addr <= next_write_addr;
			storage[write_addr] <= i_dat;
		end else if(i_read & ~o_empty) begin //priority to write, allow to use single port RAMs
			o_empty <= o_almost_empty;
			o_full <= 1'b0;
			read_addr <= next_read_addr;
			o_dat <= storage[read_addr];
		end
	end
end
endmodule



module fake_trng #(
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
	output reg [NSRC*SRC_WIDTH-1:0] o_sampled
);
always @(posedge i_clk) begin
	if(i_reset) o_sampled <= {{NSRC*SRC_WIDTH-1{1'b0}},1'b0};
	else begin
		//o_sampled <= {o_sampled[5:4],o_sampled[0+:5],o_sampled[5]^o_sampled[3]};
		o_sampled <= o_sampled + 1'b1;
	end
end
localparam CNT_WIDTH = 8;
reg [CNT_WIDTH-1:0] cnt;	
always @(posedge i_clk) begin
	if(i_reset) begin
		cnt <= {CNT_WIDTH{1'b0}};
		o_dat <= {WIDTH{1'b0}};
	end else begin
		if(i_read & o_valid) begin
			cnt <= {CNT_WIDTH{1'b0}};
			o_dat <= {WIDTH{1'b0}};
		end else begin
			o_dat <= o_dat+1'b1;//o_sampled[7:0];
			if(~o_valid) cnt <= cnt + 1'b1;
		end
	end
end
always @* o_valid = cnt==WIDTH;
endmodule
module async_trng (
	input wire i_reset,
	input wire [SRC_WIDTH-1:0] i_src_init_val,
	input wire i_clk,
	input wire i_read,
	output reg [8-1:0] o_dat,
	output reg o_valid,
	output wire [28-1:0] o_sampled
);
localparam WIDTH = 8;
localparam SRC_WIDTH = 7;
localparam SAMPLED_WIDTH = 28;
localparam TARGET_CNT = 64 * WIDTH;
wire raw_rnd;
wire [SAMPLED_WIDTH-1:0] rnd_src_dat;
async_ring u0_rnd_src (.i_reset(i_reset), .i_init_val(i_src_init_val), .o_dat(rnd_src_dat[0*SRC_WIDTH+:SRC_WIDTH]));
async_ring u1_rnd_src (.i_reset(i_reset), .i_init_val(i_src_init_val), .o_dat(rnd_src_dat[1*SRC_WIDTH+:SRC_WIDTH]));
async_ring u2_rnd_src (.i_reset(i_reset), .i_init_val(i_src_init_val), .o_dat(rnd_src_dat[2*SRC_WIDTH+:SRC_WIDTH]));
async_ring u3_rnd_src (.i_reset(i_reset), .i_init_val(i_src_init_val), .o_dat(rnd_src_dat[3*SRC_WIDTH+:SRC_WIDTH]));
entropy_extractor #(.WIDTH(SAMPLED_WIDTH)) extractor (.i_clk(i_clk), .i_rnd_src(rnd_src_dat),
	.o_sampled(o_sampled), .o_rnd(raw_rnd));
localparam CNT_WIDTH = 8;
reg [CNT_WIDTH-1:0] cnt;
reg [CNT_WIDTH-1:0] cnt2;	
always @(posedge i_clk) begin
	if(i_reset) begin
		cnt <= {CNT_WIDTH{1'b0}};
		cnt2 <= {CNT_WIDTH{1'b0}};
		o_dat <= {WIDTH{1'b0}};
	end else begin
		if(i_read & o_valid) begin
			cnt <= {CNT_WIDTH{1'b0}};
			cnt2 <= {CNT_WIDTH{1'b0}};
			o_dat <= {{WIDTH-1{1'b0}},raw_rnd};//start a new output byte, keep them independent
		end else begin
			o_dat <= {o_dat[0+:WIDTH-1],o_dat[WIDTH-1]^raw_rnd};//the xor gather entropy in case the data is not consumed immediately
			if(~o_valid) begin
				cnt <= cnt + 1'b1;
				if(cnt=={CNT_WIDTH{1'b1}}) cnt2 <= cnt2 + 1'b1;
			end
		end
	end
end
always @* o_valid = {cnt2,cnt}==TARGET_CNT;
endmodule
module entropy_extractor #(
	parameter WIDTH = 1
	)(
	input wire i_clk,
	input wire [WIDTH-1:0] i_rnd_src,
	output reg [WIDTH-1:0] o_sampled,
	output reg o_rnd
);
always @(posedge i_clk) o_sampled <= i_rnd_src;
always @(posedge i_clk) o_rnd <= ^o_sampled;
endmodule

module async_ring(
	input wire i_reset,
	input wire [7-1:0] i_init_val,
	output wire [7-1:0] o_dat
	);
	
reg [7-1:0] f_FP;
reg [7-1:0] r_FP;	
ring_stage_impl stage0(.i_reset(i_reset), 
	.i_init_val(i_init_val[0]),
	.i_f(f_FP[0]), .i_r(r_FP[0]), .o_c(o_dat[0]));
always @* begin:F0
	f_FP[0] = o_dat[6];
end
always @* begin:R0
	r_FP[0] = o_dat[1];
end
ring_stage_impl stage1(.i_reset(i_reset), 
	.i_init_val(i_init_val[1]),
	.i_f(f_FP[1]), .i_r(r_FP[1]), .o_c(o_dat[1]));
always @* begin:F1
	f_FP[1] = o_dat[0];
end
always @* begin:R1
	r_FP[1] = o_dat[2];
end
ring_stage_impl stage2(.i_reset(i_reset), 
	.i_init_val(i_init_val[2]),
	.i_f(f_FP[2]), .i_r(r_FP[2]), .o_c(o_dat[2]));
always @* begin:F2
	f_FP[2] = o_dat[1];
end
always @* begin:R2
	r_FP[2] = o_dat[3];
end
ring_stage_impl stage3(.i_reset(i_reset), 
	.i_init_val(i_init_val[3]),
	.i_f(f_FP[3]), .i_r(r_FP[3]), .o_c(o_dat[3]));
always @* begin:F3
	f_FP[3] = o_dat[2];
end
always @* begin:R3
	r_FP[3] = o_dat[4];
end
ring_stage_impl stage4(.i_reset(i_reset), 
	.i_init_val(i_init_val[4]),
	.i_f(f_FP[4]), .i_r(r_FP[4]), .o_c(o_dat[4]));
always @* begin:F4
	f_FP[4] = o_dat[3];
end
always @* begin:R4
	r_FP[4] = o_dat[5];
end
ring_stage_impl stage5(.i_reset(i_reset), 
	.i_init_val(i_init_val[5]),
	.i_f(f_FP[5]), .i_r(r_FP[5]), .o_c(o_dat[5]));
always @* begin:F5
	f_FP[5] = o_dat[4];
end
always @* begin:R5
	r_FP[5] = o_dat[6];
end
ring_stage_impl stage6(.i_reset(i_reset), 
	.i_init_val(i_init_val[6]),
	.i_f(f_FP[6]), .i_r(r_FP[6]), .o_c(o_dat[6]));
always @* begin:F6
	f_FP[6] = o_dat[5];
end
always @* begin:R6
	r_FP[6] = o_dat[0];
end
endmodule


`default_nettype wire