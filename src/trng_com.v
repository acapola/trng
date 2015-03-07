
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

function [31:0] f_reverse32;
    input [31:0] in;
    reg [31:0] tmp;
    integer i;
    begin
        for(i=0;i<32;i=i+1) tmp[i] = in[31-i];
        f_reverse32 = tmp;
    end
endfunction
function [7:0] f_reverse8;
    input [7:0] in;
    reg [7:0] tmp;
    integer i;
    begin
        for(i=0;i<8;i=i+1) tmp[i] = in[7-i];
        f_reverse8 = tmp;
    end
endfunction
//CRC32 Castagnoli 
//POLY for software implementation (depending on implementation...): 
//#define POLY 0x82f63b78
//#define POLY 0x1EDC6F41
// CRC module for data[7:0] ,   crc[31:0]=1+x^6+x^8+x^9+x^10+x^11+x^13+x^14+x^18+x^19+x^20+x^22+x^23+x^25+x^26+x^27+x^28+x^32;
//-----------------------------------------------------------------------------
function [31:0] f_crc32_castagnoli_d8;
  input [7:0] in;
  input [31:0] crc_state;
  reg [7:0] data_in;
  reg [31:0] lfsr_q,lfsr_c;

  begin
    data_in = f_reverse8(in);
    lfsr_q = f_reverse32(crc_state);
    lfsr_c[0] = lfsr_q[24] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[1] = lfsr_q[25] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[2] = lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[6] ^ data_in[7];
    lfsr_c[3] = lfsr_q[27] ^ lfsr_q[31] ^ data_in[3] ^ data_in[7];
    lfsr_c[4] = lfsr_q[28] ^ data_in[4];
    lfsr_c[5] = lfsr_q[29] ^ data_in[5];
    lfsr_c[6] = lfsr_q[24] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[0] ^ data_in[4] ^ data_in[5] ^ data_in[7];
    lfsr_c[7] = lfsr_q[25] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[1] ^ data_in[5] ^ data_in[6];
    lfsr_c[8] = lfsr_q[0] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[0] ^ data_in[2] ^ data_in[4] ^ data_in[5];
    lfsr_c[9] = lfsr_q[1] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[7];
    lfsr_c[10] = lfsr_q[2] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[6] ^ data_in[7];
    lfsr_c[11] = lfsr_q[3] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6];
    lfsr_c[12] = lfsr_q[4] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[13] = lfsr_q[5] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ data_in[0] ^ data_in[2] ^ data_in[3];
    lfsr_c[14] = lfsr_q[6] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[15] = lfsr_q[7] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[6] ^ data_in[7];
    lfsr_c[16] = lfsr_q[8] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[7];
    lfsr_c[17] = lfsr_q[9] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[3] ^ data_in[4] ^ data_in[6];
    lfsr_c[18] = lfsr_q[10] ^ lfsr_q[24] ^ lfsr_q[30] ^ data_in[0] ^ data_in[6];
    lfsr_c[19] = lfsr_q[11] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[6];
    lfsr_c[20] = lfsr_q[12] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[4];
    lfsr_c[21] = lfsr_q[13] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[5];
    lfsr_c[22] = lfsr_q[14] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[7];
    lfsr_c[23] = lfsr_q[15] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[5] ^ data_in[7];
    lfsr_c[24] = lfsr_q[16] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[6];
    lfsr_c[25] = lfsr_q[17] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6];
    lfsr_c[26] = lfsr_q[18] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[6];
    lfsr_c[27] = lfsr_q[19] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[5] ^ data_in[6];
    lfsr_c[28] = lfsr_q[20] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5];
    lfsr_c[29] = lfsr_q[21] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6];
    lfsr_c[30] = lfsr_q[22] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[31] = lfsr_q[23] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    f_crc32_castagnoli_d8 = f_reverse32(lfsr_c);
  end
endfunction
	
reg [7:0] to_send;
wire tx_ready;
reg tx_write;
tx u_tx(
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_cycles_per_bit(CYCLES_PER_BIT),
	.i_write(tx_write),
	.i_dat(to_send),
	.i_rts_n(i_serial_rts_n),
	.o_sout(o_serial_data),
	.o_ready(tx_ready)
	);
	
wire [7:0] com_data = i_dat;
wire data_ready = i_write;
localparam PACKET_SOF_SIZE = 4;
localparam PACKET_DATA_SIZE = 128;
localparam PACKET_CHECKSUM_SIZE = 4;
localparam PACKET_SIZE = PACKET_SOF_SIZE + PACKET_DATA_SIZE + PACKET_CHECKSUM_SIZE;
reg [7:0] frame_bytes_cnt;
always @* o_new_frame = (frame_bytes_cnt==8'h00) & (tx_ready & ~tx_write);//1 cycle pulse
reg [31:0] crc;
wire [1:0] byte_index = frame_bytes_cnt[1:0];
reg ready;
always @* o_ready = ready & ~i_write & ~tx_write;
always @(posedge i_clk) begin
	if(i_reset) begin
		frame_bytes_cnt <= {8{1'b0}};
		ready <= 1'b0;
		tx_write <= 1'b0;
	end else if(tx_ready & ~tx_write) begin
		if(frame_bytes_cnt<PACKET_SOF_SIZE) begin
			tx_write <= 1'b1;
			frame_bytes_cnt <= (frame_bytes_cnt + 1'b1) % PACKET_SIZE;
			to_send <= frame_bytes_cnt;
			crc <= {32{1'b1}};
			ready <= 1'b0;
		end else if(frame_bytes_cnt<PACKET_SOF_SIZE + PACKET_DATA_SIZE) begin
			if(data_ready) begin
				ready <= 1'b1;
				tx_write <= 1'b1;
				frame_bytes_cnt <= (frame_bytes_cnt + 1'b1) % PACKET_SIZE;
				to_send <= com_data;
				crc <= f_crc32_castagnoli_d8(com_data,crc);
			end else begin
				ready <= 1'b1;
			end
		end else begin
			ready <= 1'b0;
			tx_write <= 1'b1;
			frame_bytes_cnt <= (frame_bytes_cnt + 1'b1) % PACKET_SIZE;
			to_send <= crc[byte_index*8+:8];
		end
	end else begin
		tx_write <= 1'b0;
		ready <= tx_ready & ~tx_write;
	end
end
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