`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:46:02 10/05/2014 
// Design Name: 
// Module Name:    lx150t_trng_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lx150t_trng_top(
	input wire RESET,
	input wire CLK,
	input wire [7:0] DIP_Switches_8Bits_TRI_I,
	input wire RS232_USB_sin,
	output wire RS232_USB_sout,
	output reg [7:0] LEDs_8Bits_TRI_O
    );

//always @* RS232_USB_sout = RS232_USB_sin;
localparam SHIFT = 20;
reg [SHIFT+16-1:0] cnt;
wire [7:0] rnd;
always @(posedge CLK) begin
	if(RESET) cnt <= {32{1'b0}};
	else cnt <= cnt + 1'b1;
	if(cnt[SHIFT+6]) LEDs_8Bits_TRI_O <= DIP_Switches_8Bits_TRI_I[7] ? rnd : cnt[SHIFT+8+:8];
end
//always @* LEDs_8Bits_TRI_O = DIP_Switches_8Bits_TRI_I ^ cnt[SHIFT+:8]; 

wire read;
wire valid;

reg [3:0] data;
always @(posedge CLK) begin
	if(RESET) data <= {4{1'b0}};
	else if(valid & read) data <= data + 1'b1;
end
function [7:0] to_ascii_hex;
	input [3:0] in;
	to_ascii_hex = in>9 ? (8'd65 - 8'd10) + in : 8'd48 + in;
endfunction
wire [7:0] to_send = DIP_Switches_8Bits_TRI_I[7] ? rnd : to_ascii_hex(data);
wire i_serial_rts_n=1'b0;
assign rnd[7:4] = 4'h0;
trng_top u_trng_top(
	.i_reset(RESET),
	.i_clk(CLK),
	.i_serial_rts_n(i_serial_rts_n),
	.o_serial_data(RS232_USB_sout),
	.o_dat_cnt(rnd[3:0])/*,
	.o_spy_a(o_spy_a),
	.o_spy_b(o_spy_b),
	.o_spy_c(o_spy_c)*/
    );
/*
tx u_tx(
	.i_reset(RESET),
	.i_clk(CLK),
	.i_cycles_per_bit(5208),
	.i_write(valid),
	.i_dat(to_send),
	.o_sout(RS232_USB_sout),
	.o_ready(read)
	);

async_trng #(.WIDTH(8),.SRC_WIDTH(7)) trng (
	.i_reset(RESET),
	.i_src_init_val(DIP_Switches_8Bits_TRI_I[6:0]),
	.i_clk(CLK),
	.i_read(read),
	.o_dat(rnd),
	.o_valid(valid)
);*/

endmodule

/*
module tx(
	input wire i_reset,
	input wire i_clk,
	input wire [31:0] i_cycles_per_bit,
	input wire i_write,
	input wire [7:0] i_dat,
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
		o_ready <= 1'b1;
		o_sout <= 1'b1;//keep line high on idle
	end else begin
		if(idle) begin
			if(i_write) begin
				o_sout <= 1'b0;//start bit
				txbuf <= i_dat;
				cnt <= cnt + 1'b1;
				o_ready <= 1'b0;
			end
		end else begin
			if(bit_cnt==i_cycles_per_bit) begin
				o_sout <= txbuf[0];
				txbuf <= {1'b1,txbuf[7:1]};//fill with 1 to send the stop bit
				bit_cnt <= {32{1'b0}};
				if(cnt==10) begin
					cnt <= {8{1'b0}};
					o_ready <= 1'b1;
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
*/