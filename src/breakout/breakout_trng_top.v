`timescale 1ns / 1ps
`define ICE40
`default_nettype none
module breakout_trng_top(
	//input wire RESET,
	input wire CLK,
	//input wire i_serial_data,
	input wire i_serial_rts_n,
	output wire o_serial_data,
	output reg [4:0] o_led
	//,output wire CLKOP
	/*,
    output wire [7:0] o_spy_a,
	output wire [7:0] o_spy_b,
	output wire [7:0] o_spy_c*/
    );

reg [31:0]  rst_count ;
wire        RESET ;

// PLL instantiation
wire CLKOP;
wire unused_clk;
trng_pll_96MHz ice_pll_inst(
     .REFERENCECLK ( CLK           ),  // input 12MHz
     .PLLOUTCORE   ( unused_clk    ),  // output 96MHz
     .PLLOUTGLOBAL ( CLKOP  ),
     .RESET        ( 1'b1  )
     );

// internal reset generation
//initial rst_count = 0;
always @ (posedge CLK) begin
	if (RESET) rst_count <= rst_count + 1'b1;
end
assign RESET = ~rst_count[27] ;
always @* o_led[4] = RESET;	

wire [3:0] dat_cnt;
	
localparam SHIFT = 19;
reg [SHIFT+16-1:0] cnt;
always @(posedge CLKOP) begin
	if(RESET) cnt <= {32{1'b0}};
	else cnt <= cnt + 1'b1;
	if(cnt[SHIFT+4]) o_led[3:0] <= dat_cnt;
end 

trng_top u_trng_top(
	.i_reset(RESET),
	.i_clk(CLKOP),
	.i_serial_rts_n(i_serial_rts_n),
	.o_serial_data(o_serial_data),
	.o_dat_cnt(dat_cnt)/*,
	.o_spy_a(o_spy_a),
	.o_spy_b(o_spy_b),
	.o_spy_c(o_spy_c)*/
    );

endmodule
`default_nettype wire