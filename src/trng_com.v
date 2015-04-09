
`default_nettype none
module trng_com(
	input wire i_reset,
	input wire i_clk,
	input wire i_serial_rts_n,
	input wire [7:0] i_dat,
	input wire i_write,
	output reg o_ready,
	output wire o_serial_data,
	output reg o_new_frame
	);
	
	
localparam TARGET_BAUDRATE = 3000000.0;
localparam CLK_HZ = 96000000;
localparam ONE_SEC_IN_NS = 1000000000.0;
localparam TARGET_BIT_PERIOD_NS = 333.3333333333333;
localparam CLK_PERIOD_NS = 10.416666666666666;
localparam CYCLES_PER_BIT_FLOAT = 32.0;
localparam CYCLES_PER_BIT = 32;
	
wire tx_ready;
always @* begin	
	o_ready = tx_ready & ~i_write;
	o_new_frame = i_write;
end
tx u_tx(
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_cycles_per_bit(CYCLES_PER_BIT),
	.i_write(i_write),
	.i_dat(i_dat),
	.i_rts_n(i_serial_rts_n),
	.o_sout(o_serial_data),
	.o_ready(tx_ready)
	);

endmodule


//simple protocol layer to send data by packets of up to 127 bytes
//over the trng_com protocol
module packet_com(
	input wire i_reset,
	input wire i_clk,
	input wire i_serial_rts_n,
	input wire i_start_packet,
	input wire [6:0] i_packet_size,
	input wire [7:0] i_dat,
	input wire i_write,
	output reg o_ready,
	output reg o_packet_ongoing,
	output wire o_serial_data,
	output wire o_new_frame
	);
wire com_ready;
reg [7:0] com_dat;
reg com_write;

reg [6:0] remaining;

reg ready;
always @* o_ready = ready & com_ready & ~i_write & ~com_write;
always @(posedge i_clk) begin
	if(i_reset) begin
		remaining <= {7{1'b0}};
		o_packet_ongoing <= 1'b0;
		ready <= 1'b0;
		com_write <= 1'b0;
	end else if(i_start_packet) begin
		remaining <= i_packet_size;
		o_packet_ongoing <= 1'b1;
		com_write <= 1'b0;
	end else if(remaining>0) begin
		if(i_write & com_ready) begin
			ready <= 1'b0;
			remaining <= remaining - 1'b1;
			com_dat <= i_dat;
			com_write <= 1'b1;
		end else begin
			com_write <= 1'b0;
			ready <= com_ready;
		end
	end else if(o_new_frame) begin
		o_packet_ongoing <= 1'b0;
		com_write <= 1'b0;
	end else if(o_packet_ongoing & com_ready) begin
		com_dat <= 8'h00;//padding
		com_write <= 1'b1;
	end else begin
		ready <= o_packet_ongoing ? (remaining>0) & com_ready : 1'b1;
		com_write <= 1'b0;
	end
end
	
trng_com u_trng_com(
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_serial_rts_n(i_serial_rts_n),
	.i_dat(com_dat),
	.i_write(com_write),
	.o_ready(com_ready),
	.o_serial_data(o_serial_data),
	.o_new_frame(o_new_frame)
	);
endmodule

module tx(
	input wire i_reset,
	input wire i_clk,
	input wire [31:0] i_cycles_per_bit,
	input wire i_write,
	input wire [7:0] i_dat,
	input wire i_rts_n,
	output reg o_sout,
	output reg o_ready
	);
reg [7:0] txbuf;
reg [3:0] cnt;
reg [31:0] bit_cnt;
wire idle = cnt==0;
always @(posedge i_clk, posedge i_reset) begin
	if(i_reset) begin
		cnt <= {8{1'b0}};
		bit_cnt <= {32{1'b0}};
		o_ready <= 1'b0;
		o_sout <= 1'b1;//keep line high on idle
	end else begin
		if(idle) begin
			if(i_rts_n) begin
				o_ready <= 1'b0;
			end else if(i_write) begin
				o_sout <= 1'b0;//start bit
				txbuf <= i_dat;
				cnt <= cnt + 1'b1;
				o_ready <= 1'b0;
			end else begin
				o_ready <= 1'b1;
			end
		end else begin
			if(bit_cnt==i_cycles_per_bit) begin
				o_sout <= txbuf[0];
				txbuf <= {1'b1,txbuf[7:1]};//fill with 1 to send the stop bit
				bit_cnt <= {32{1'b0}};
				if(cnt==10) begin
					cnt <= {8{1'b0}};
					o_ready <= ~i_rts_n;
				end else begin
					cnt <= cnt + 1'b1;
				end
			end else begin
				bit_cnt <= bit_cnt + 1'b1;
			end
		end
	end
end
endmodule

`default_nettype wire