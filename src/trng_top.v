
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

localparam TRNG_NSRC = 1;
localparam TRNG_SRC_WIDTH = 32;
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
//wire [TRNG_NSRC*TRNG_SRC_WIDTH-1:0] fake_trng_sampled;
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

lfsr_trng trng (
	.i_reset(trng_reset),
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(trng_dat),
	.o_valid(trng_valid),
	.o_sampled(trng_sampled)
);
/*fake_trng #(.WIDTH(TRNG_OUT_WIDTH),.NSRC(TRNG_NSRC), .SRC_WIDTH(TRNG_SRC_WIDTH)) u_fake_trng (
	.i_reset(1'b0),//we output o_sampled only during reset time...
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(),
	.o_valid(),
	.o_sampled(fake_trng_sampled)
);*/



endmodule

module fake_trng #(
	parameter WIDTH = 8,//max is 255
	parameter NSRC = 1,//number of rings running in parallel
	parameter SRC_WIDTH = 5//size of each ring
	)(
	input wire i_reset,
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
module lfsr_trng (
	input wire i_reset,
	input wire i_clk,
	input wire i_read,
	output reg [8-1:0] o_dat,
	output reg o_valid,
	output wire [32-1:0] o_sampled
) /* synthesis syn_hier = "hard" */ ;

// polynomial: (0 1 2 8)
// data width: 32
// convention: the first serial bit is D[31]
function [7:0] nextCRC8_D32;
	input [31:0] Data;
	input [7:0] crc;
	reg [31:0] d;
	reg [7:0] c;
	reg [7:0] newcrc;
	begin
		d = Data;
		c = crc;

		newcrc[0] = d[31] ^ d[30] ^ d[28] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[16] ^ d[14] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[0] ^ c[4] ^ c[6] ^ c[7];
		newcrc[1] = d[30] ^ d[29] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[9] ^ d[6] ^ d[1] ^ d[0] ^ c[0] ^ c[4] ^ c[5] ^ c[6];
		newcrc[2] = d[29] ^ d[28] ^ d[25] ^ d[24] ^ d[22] ^ d[17] ^ d[15] ^ d[13] ^ d[12] ^ d[10] ^ d[8] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[1] ^ c[4] ^ c[5];
		newcrc[3] = d[30] ^ d[29] ^ d[26] ^ d[25] ^ d[23] ^ d[18] ^ d[16] ^ d[14] ^ d[13] ^ d[11] ^ d[9] ^ d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[1] ^ c[2] ^ c[5] ^ c[6];
		newcrc[4] = d[31] ^ d[30] ^ d[27] ^ d[26] ^ d[24] ^ d[19] ^ d[17] ^ d[15] ^ d[14] ^ d[12] ^ d[10] ^ d[8] ^ d[4] ^ d[3] ^ d[2] ^ c[0] ^ c[2] ^ c[3] ^ c[6] ^ c[7];
		newcrc[5] = d[31] ^ d[28] ^ d[27] ^ d[25] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[13] ^ d[11] ^ d[9] ^ d[5] ^ d[4] ^ d[3] ^ c[1] ^ c[3] ^ c[4] ^ c[7];
		newcrc[6] = d[29] ^ d[28] ^ d[26] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[14] ^ d[12] ^ d[10] ^ d[6] ^ d[5] ^ d[4] ^ c[2] ^ c[4] ^ c[5];
		newcrc[7] = d[30] ^ d[29] ^ d[27] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[15] ^ d[13] ^ d[11] ^ d[7] ^ d[6] ^ d[5] ^ c[3] ^ c[5] ^ c[6];
		nextCRC8_D32 = newcrc;
	end
endfunction

localparam NCRC = 1;
localparam CRC_STATE_WIDTH = 8;
localparam WIDTH = 8;
reg [CRC_STATE_WIDTH-1:0] crc_state;
wire [CRC_STATE_WIDTH-1:0] crc_input = i_read & o_valid ? {CRC_STATE_WIDTH{1'b0}} : crc_state;//start a new output byte, keep them independent
wire [CRC_STATE_WIDTH-1:0] crc_sampled = nextCRC8_D32(o_sampled,crc_input);
always @(*) o_dat = crc_state;
localparam SRC_WIDTH = 32;
localparam SAMPLED_WIDTH = 32;
localparam TARGET_CNT = 104 * WIDTH /8;
lfsrentsrc #(.RNG_WIDTH(SRC_WIDTH)) u0_rnd_src (.i_reset(i_reset), .i_clk(i_clk), .i_en(1'b1), .o_rnd(o_sampled[0*SRC_WIDTH+:SRC_WIDTH]));
localparam CNT_WIDTH = 4;
reg [CNT_WIDTH-1:0] cnt;
reg [CNT_WIDTH-1:0] cnt2;	
always @(posedge i_clk) begin
	if(i_reset) begin
		cnt <= {CNT_WIDTH{1'b0}};
		cnt2 <= {CNT_WIDTH{1'b0}};
		crc_state <= {CRC_STATE_WIDTH{1'b0}};
	end else begin
		if(i_read & o_valid) begin
			cnt <= {CNT_WIDTH{1'b0}};
			cnt2 <= {CNT_WIDTH{1'b0}};
			crc_state <= crc_sampled;
		end else begin
			crc_state <= crc_sampled;
			if(~o_valid) begin
				cnt <= cnt + 1'b1;
				if(cnt=={CNT_WIDTH{1'b1}}) cnt2 <= cnt2 + 1'b1;
			end
		end
	end
end
always @* o_valid = {cnt2,cnt}==TARGET_CNT;
endmodule
	
`default_nettype wire