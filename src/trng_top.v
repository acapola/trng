
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
wire trng_read = com_ready & trng_valid;
wire [7:0] trng_dat;
wire com_new_frame;
reg send;
reg [7:0] to_send;
always @(posedge i_clk) begin
	if(i_reset) begin
		send <= 1'b0;
	end else begin
		if(com_ready & trng_valid) begin
			send <= 1'b1;
			to_send <= trng_dat;
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


reg [15:0] reset_guard_cnt;
wire reset_guard_time = 128 != reset_guard_cnt;

always @* trng_reset = i_reset;

always @(posedge i_clk) begin
	if(i_reset ) reset_guard_cnt <= {16{1'b0}};
	else if(reset_guard_time) reset_guard_cnt <= reset_guard_cnt + 1'b1;
end


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
fake_trng #(.WIDTH(TRNG_OUT_WIDTH),.NSRC(TRNG_NSRC), .SRC_WIDTH(TRNG_SRC_WIDTH)) trng (
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
	.i_src_init_val(TRNG_SRC_INIT),//not used
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(),
	.o_valid(),
	.o_sampled(fake_trng_sampled)
);



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
			o_dat <= o_dat+1'b1;
		end else begin
			//o_dat <= o_dat+1'b1;//o_sampled[7:0];
			//if(~o_valid) cnt <= cnt + 1'b1;
		end
	end
end
always @* o_valid = 1;//cnt==WIDTH;
endmodule
`default_nettype wire