`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:00:49 10/04/2014
// Design Name:   async_trng
// Module Name:   C:/Users/seb/trng/src/trng_tb.v
// Project Name:  trng
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: async_trng
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module top_tb;

	// Inputs
	reg i_reset;
	reg [7:0] i_src_init_val;
	reg i_clk;
	reg i_read;

	// Outputs
	wire o_dat;
	wire [7:0] o_sampled;

	// Instantiate the Unit Under Test (UUT)
	lx150t_trng_top uut (
		.RESET(i_reset), 
		.DIP_Switches_8Bits_TRI_I(i_src_init_val), 
		.CLK(i_clk), 
		.RS232_USB_sin(1'b0), 
		.RS232_USB_sout(o_dat), 
		.LEDs_8Bits_TRI_O(o_sampled)
	);

	initial begin
		// Initialize Inputs
		i_reset = 1;
		i_src_init_val = 8'b10101010;
		
		// Wait 100 ns for global reset to finish
		#300;
      i_reset = 0;  
		// Add stimulus here
		#4000;
		$finish;
	end

initial begin
    i_clk = 0;
    forever i_clk = #100 ~i_clk;
end
      
endmodule

