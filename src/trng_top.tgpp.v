``
#config
::tgpp::source async_trng_lib.tgpp.v
::tgpp::source sb_trng_lib.tgpp.v

set TRNG_IMPL sb_trng
#set TRNG_IMPL async_trng
#set TRNG_IMPL fake_trng

set init_input 1
#min is 1 (normal sampling)
#max is 1K
set TRNG_OVERSAMPLING 1

#set to 0 to observe the very first samples
set RESET_GUARD_CYCLES 512
	

set TRNG_CRC_SAMPLING 1

#select one test at most
set TRNG_AUTOCO 0
set TRNG_RAW 0
set TRNG_RESET_TEST 0

#AUTOCO parameters
set AUTOCO_DELTA_WIDTH 6
set AUTOCO_OUT_WIDTH 8
set AUTOCO_WIDTH 7
set AUTOCO_OFFSET 0
set AUTOCO_MERGE 1

#no periodic reset by default
set PERIODIC_RESET 0
#no fifo by default
set HAS_FIFO 0

#RAW parameters
if {$TRNG_RAW} {
	set RAW_WIDTH_BYTES 4
	set PERIODIC_RESET 1
	set HAS_FIFO 1
}

#RESET_TEST parameters
if {$TRNG_RESET_TEST} {
	#reset after each FIFO fill up (16K on hx8k)
	set PERIODIC_RESET 1
	set HAS_FIFO 1
}

#fixed/computed parameters

#TRNG_APP: 1 if we build the real application.
#This is set to 1 later on if no test config active.
set TRNG_APP 0
#TRNG_TEST: 1 if we build a test
set TRNG_TEST [expr $TRNG_AUTOCO | $TRNG_RAW | $TRNG_RESET_TEST]


if {$TRNG_TEST} {
#config to characterize the entropy source by recording the raw data in a FIFO
	switch $TRNG_IMPL {
		sb_trng {
			set init_input 0
			set BYTE_ALIGNED_SAMPLED_DATA {wire [31:0] byteAlignedSampledData = trng_sampled;}
			set TRNG_NSRC 1
			set TRNG_SRC_WIDTH 32	
		}
		async_trng -
		default {
			set config4x7s {
				set BYTE_ALIGNED_SAMPLED_DATA {wire [31:0] byteAlignedSampledData = {trng_sampled[3*7+:7],1'b0,trng_sampled[2*7+:7],1'b0,trng_sampled[1*7+:7],1'b0,trng_sampled[0*7+:7],1'b0};}
				set TRNG_NSRC 4
				set TRNG_SRC_WIDTH 7
				#set TRNG_SRC_INIT 7'b1001010
				#set TRNG_SRC_INIT 7'b1001000
				set init_value [list 0 1 0 1 0 0 1]
				#set init_value [list 0 0 0 1 0 0 1]
				#set init_value  [list 0 1 0 1 0 0 0]
			}
			set config32s {
				set BYTE_ALIGNED_SAMPLED_DATA {wire [31:0] byteAlignedSampledData = trng_sampled;}
				set TRNG_NSRC 1
				set TRNG_SRC_WIDTH 32
				#set TRNG_SRC_INIT 32'h75_55_55_55
				#set TRNG_SRC_INIT 32'h4C_70_F0_7C
				#set TRNG_SRC_INIT 32'h4CC770F0
				#set TRNG_SRC_INIT 32'h0000FFFF
				#set TRNG_SRC_INIT 32'h0F0F0F0F
				set init_value [list 0 1 0 0 1 1 0 0   0 1 1 1 0 0 0 0   1 1 1 1 0 0 0 0    0 1 1 1 1 1 0 0]
			}
			set config33s {
				set BYTE_ALIGNED_SAMPLED_DATA {wire [31:0] byteAlignedSampledData = trng_sampled;}
				set TRNG_NSRC 1
				set TRNG_SRC_WIDTH 33
				#set TRNG_SRC_INIT 33'h75_55_55_55
				#set TRNG_SRC_INIT 33'h4C_70_F0_7C
				set init_value [list 0    0 1 0 0 1 1 0 0   0 1 1 1 0 0 0 0   1 1 1 1 0 0 0 0    0 1 1 1 1 1 0 0]
			}
			eval $config4x7s
		}
	}
} else {
	#config to produce the best random numbers 
	switch $TRNG_IMPL {
		sb_trng {
			set init_input 0
			set BYTE_ALIGNED_SAMPLED_DATA {wire [31:0] byteAlignedSampledData = trng_sampled;}
			set TRNG_NSRC 1
			set TRNG_SRC_WIDTH 32	
		}
		async_trng -
		default {
			set TRNG_APP 1
			set TRNG_TEST 0

			set TRNG_NSRC 4
			set TRNG_SRC_WIDTH 7
			#set TRNG_SRC_INIT 7'b1001010
			set init_value [list 0 1 0 1 0 0 1]
		}
	}
}
if {$init_input} {
	set len [llength $init_value]
	set TRNG_SRC_INIT ""
	foreach bit $init_value {
		append TRNG_SRC_INIT $bit
	}
	set TRNG_SRC_INIT "${len}'b[string reverse $TRNG_SRC_INIT]"
	#code will use TRNG_SRC_INIT
	set init_value [list]
}
set TRNG_OUT_WIDTH 8
``

`backtick`default_nettype none
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

localparam TRNG_NSRC = `$TRNG_NSRC`;
localparam TRNG_SRC_WIDTH = `$TRNG_SRC_WIDTH`;
``if {$init_input} {``
localparam TRNG_SRC_INIT = `$TRNG_SRC_INIT`;
``}``
localparam TRNG_OUT_WIDTH = `$TRNG_OUT_WIDTH`;

reg trng_reset;
wire com_ready;	
wire trng_valid;
``if {$HAS_FIFO} {``
wire trng_read = trng_valid;
``} else {``
wire trng_read = com_ready;
``}``
wire [7:0] trng_dat;
wire com_new_frame;
reg send;
reg [7:0] to_send;
``if $TRNG_AUTOCO {``
localparam AUTOCO_DELTA_WIDTH = `$AUTOCO_DELTA_WIDTH`;
localparam AUTOCO_OUT_WIDTH = `$AUTOCO_OUT_WIDTH`;
localparam AUTOCO_WIDTH = `$AUTOCO_WIDTH`;
localparam AUTOCO_OFFSET = `$AUTOCO_OFFSET`;
localparam AUTOCO_OUT_WIDTH_BYTES = 1;//TODO
localparam AUTOCO_DELTA_WIDTH_BYTES = 1;//TODO
localparam PACKET_SIZE_BYTES = 1+2*AUTOCO_OUT_WIDTH_BYTES+AUTOCO_DELTA_WIDTH_BYTES;
localparam PACKET_SIZE = PACKET_SIZE_BYTES *8;
reg autoco_init;
reg [AUTOCO_DELTA_WIDTH-1:0] autoco_delta;
wire [AUTOCO_OUT_WIDTH-1:0] autoco_write_cnt;
wire [AUTOCO_OUT_WIDTH-1:0] autoco_match_cnt;
wire autoco_full;
reg [AUTOCO_WIDTH-1:0] mask;
``if $AUTOCO_MERGE {``
reg autoco_dat;
always @(posedge i_clk) autoco_dat <= ^(trng_sampled[AUTOCO_OFFSET+:AUTOCO_WIDTH] & mask);
``} else {``
reg [AUTOCO_WIDTH-1:0] autoco_dat;
always @(posedge i_clk) autoco_dat <= trng_sampled[AUTOCO_OFFSET+:AUTOCO_WIDTH] & mask;
``}``
auto_correlation #(
``if $AUTOCO_MERGE {``
	.WIDTH(1),
``} else {``
	.WIDTH(AUTOCO_WIDTH),
``}``
	.OUT_WIDTH(AUTOCO_OUT_WIDTH),
	.DELTA_WIDTH(AUTOCO_DELTA_WIDTH)
	) u_autoco (
	.i_clk(i_clk),
	.i_init(autoco_init),//one cycle pulse to start a new computation
	.i_delta(autoco_delta),
	.i_dat(autoco_dat),
	.i_write(1'b1),
	.o_write_cnt(autoco_write_cnt),
	.o_match_cnt(autoco_match_cnt),
	.o_full(autoco_full) //high if it can't accept new data (o_write_cnt has its max value)
);

reg [1:0] sent_cnt;
reg com_start_packet;
//wire [PACKET_SIZE-1:0] packet_data = {autoco_match_cnt,autoco_write_cnt,autoco_delta};
wire com_packet_ongoing;
reg [4:0] mask_cnt;
always @(posedge i_clk) begin
	if(i_reset) begin
		autoco_delta <= {AUTOCO_DELTA_WIDTH{1'b0}};
		autoco_init <= 1'b1;
		sent_cnt <= 0;
		com_start_packet <= 1'b0;
		send <= 1'b0;
		mask <= 1'b1;
		mask_cnt <= 0;
	end else if(com_ready & autoco_full) begin
		if(com_packet_ongoing) begin
			com_start_packet <= 1'b0;
			send <= 1'b1;
			//to_send <= packet_data[8*(sent_cnt%PACKET_SIZE_BYTES)+:8];
			case(sent_cnt)
			2'b00: to_send <= autoco_delta;
			2'b01: to_send <= autoco_match_cnt;
			2'b10: to_send <= autoco_write_cnt;
			2'b11: to_send <= mask;
			endcase
			if(sent_cnt==PACKET_SIZE_BYTES-1) begin
				autoco_init <= 1'b1;
				sent_cnt <= 0;
				autoco_delta <= autoco_delta + 1'b1;
				if( &autoco_delta ) begin
					if( &mask_cnt ) mask <= {mask[0+:AUTOCO_WIDTH-1],~mask[AUTOCO_WIDTH-1]};
					mask_cnt <= mask_cnt+1'b1;
				end
			end else begin
				sent_cnt <= sent_cnt + 1'b1;
			end
		end else begin
			com_start_packet <= 1'b1;
		end
	end  else begin
		autoco_init <= 1'b0;
		send <= 1'b0;
		com_start_packet <= 1'b0;
	end
end

packet_com u_packet_com(
	.i_start_packet(com_start_packet),
	.i_packet_size(PACKET_SIZE_BYTES),
	.o_packet_ongoing(com_packet_ongoing),
``} elseif {$HAS_FIFO} {``
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
``} else {``
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
``}``
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
wire reset_guard_time = `$RESET_GUARD_CYCLES` != reset_guard_cnt;

``if {$PERIODIC_RESET} {``
reg [15:0] periodic_reset_cnt;
wire fifo_emptied = (~ram_valid) & fifo_read_l1;//single cycle pulse
wire periodic_reset = fifo_emptied & (periodic_reset_cnt==`$PERIODIC_RESET`);
reg periodic_reset_l1;
always @(posedge i_clk) periodic_reset_l1 <= periodic_reset;//register to have at least one full clock cycle to reset the trng
always @(posedge i_clk) begin
	if(i_reset | periodic_reset) periodic_reset_cnt <= {{15{1'b0}},1'b1};
	else if(fifo_emptied) periodic_reset_cnt <= periodic_reset_cnt + 1'b1;	
end
reg fifo_write;
always @(posedge i_clk) fifo_write <= ~ram_valid & ~reset_guard_time & ~periodic_reset``if {$TRNG_RESET_TEST} {`` & trng_valid``}``;//fifo_write remains high for 1 cycle more than needed but fifo ignore it so no data is overwritten
always @* trng_reset = i_reset | periodic_reset_l1;
``} else {
	if {$HAS_FIFO} {``
wire fifo_write = ~ram_valid & ~reset_guard_time;
``	}``
always @* trng_reset = i_reset;
``}``

always @(posedge i_clk) begin
	if(i_reset ``if {$PERIODIC_RESET} {``| periodic_reset``}``) reset_guard_cnt <= {16{1'b0}};
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
``switch $TRNG_IMPL {
	fake_trng {``
fake_trng #(.WIDTH(TRNG_OUT_WIDTH),.NSRC(TRNG_NSRC), .SRC_WIDTH(TRNG_SRC_WIDTH))``
	}
	default {``
`$TRNG_IMPL```
	}
} `` trng (
	.i_reset(trng_reset),
``if {$init_input} {``	
	.i_src_init_val(TRNG_SRC_INIT),
``}``	
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(trng_dat),
	.o_valid(trng_valid),
	.o_sampled(trng_sampled)
);
fake_trng #(.WIDTH(TRNG_OUT_WIDTH),.NSRC(TRNG_NSRC), .SRC_WIDTH(TRNG_SRC_WIDTH)) u_fake_trng (
	.i_reset(1'b0),//we output o_sampled only during reset time...
``if {$init_input} {``	
	.i_src_init_val(TRNG_SRC_INIT),//not used
``}``	
	.i_clk(i_clk),
	.i_read(trng_read),
	.o_dat(),
	.o_valid(),
	.o_sampled(fake_trng_sampled)
);



``if {$TRNG_RAW | $TRNG_RESET_TEST} {
if {$TRNG_RAW} {
	set FIFO_IN_WIDTH_BYTES $RAW_WIDTH_BYTES
} else {
	set FIFO_IN_WIDTH_BYTES [expr $TRNG_OUT_WIDTH/8]
}

#works up to RAW_WIDTH_BYTES=4
set FIFO_DEPTH_WIDTH [expr (3+11)-($FIFO_IN_WIDTH_BYTES/2)]
``
localparam FIFO_IN_WIDTH_BYTES = `$FIFO_IN_WIDTH_BYTES`;
localparam FIFO_DEPTH_WIDTH = `$FIFO_DEPTH_WIDTH`;
//we store sampled data in ram until its full and then dump the full memory
``if {$TRNG_RAW} {``
`$BYTE_ALIGNED_SAMPLED_DATA`
wire [FIFO_IN_WIDTH_BYTES*8-1:0] fifo_in = byteAlignedSampledData[FIFO_IN_WIDTH_BYTES*8-1:0];
``} else {``
reg [FIFO_IN_WIDTH_BYTES*8-1:0] fifo_in;
always @(posedge i_clk) fifo_in <= trng_dat[FIFO_IN_WIDTH_BYTES*8-1:0];//pipeline reg because fifo_write is delayed as well
``}``
wire fifo_empty,fifo_full;
fifo #(
	.DEPTH_WIDTH(FIFO_DEPTH_WIDTH)//`expr (1<<$FIFO_DEPTH_WIDTH)*$FIFO_IN_WIDTH_BYTES` bytes FIFO
	) u_fifo (
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_write(fifo_write),
	.i_read(fifo_read),
	.i_dat(fifo_in),
	.o_dat(fifo_out),
	.o_almost_empty(fifo_empty),
``if {$TRNG_RAW} {``	
	.o_almost_full(fifo_full)
``} else {``
	.o_full(fifo_full)
``}``	
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
``}``

endmodule
``if {$HAS_FIFO} {
tgpp::source fifo_lib.tgpp.v
``
`fifo_module fifo [expr 8*$FIFO_IN_WIDTH_BYTES] 8`
``}``

``if {$TRNG_IMPL=="fake_trng"} {``
``}``
module fake_trng #(
	parameter WIDTH = 8,//max is 255
	parameter NSRC = 1,//number of rings running in parallel
	parameter SRC_WIDTH = 5//size of each ring
	)(
	input wire i_reset,
``if {$init_input} {``	
	input wire [SRC_WIDTH-1:0] i_src_init_val,
``}``	
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
``switch $TRNG_IMPL {
	sb_trng {``
`sb_trng_module sb_trng $TRNG_OUT_WIDTH $TRNG_NSRC $TRNG_SRC_WIDTH $TRNG_OVERSAMPLING`	
``  }	
	async_trng {``
`async_trng_module async_trng $TRNG_OUT_WIDTH $TRNG_NSRC $TRNG_SRC_WIDTH $TRNG_OVERSAMPLING $TRNG_CRC_SAMPLING $init_value`
``	}
}``
`backtick`default_nettype wire