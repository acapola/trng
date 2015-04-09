`timescale 1ns / 1ps
`define ICE40
`default_nettype none
module icestick_trng_top(	//input wire RESET,
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
/*	
LED_Rotation impl(
	.clk(CLK), 
	.LED1(o_led[0]),
	.LED2(o_led[1]),
	.LED3(o_led[2]),
	.LED4(o_led[3]),
	.LED5(o_led[4])
	);

assign o_serial_data = 1'b1;
*/
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
	.o_dat_cnt(dat_cnt)
    );

endmodule

module LED_Rotation(
    input  wire clk,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5
    );

	reg[15:0] div_cntr1;
	reg[6:0] div_cntr2;
	reg[1:0] dec_cntr;
	reg half_sec_pulse;
		
	always@(posedge clk)
		begin
		div_cntr1 <= div_cntr1 + 1;
		if (div_cntr1 == 0) 
			if (div_cntr2 == 31) 
				begin
				div_cntr2 <= 0;
				half_sec_pulse <= 1;  
				end
			else
				div_cntr2 <= div_cntr2 + 1;
		else
			half_sec_pulse <= 0;
		
		if (half_sec_pulse == 1)	
			dec_cntr <= dec_cntr + 1;
			
		end	
		
		
	assign LED1 = (dec_cntr == 0) ;
	assign LED2 = (dec_cntr == 1) ;
	assign LED3 = (dec_cntr == 2) ;
	assign LED4 = (dec_cntr == 3) ;
	assign LED5 = 1'b1;
				
endmodule
`default_nettype wire