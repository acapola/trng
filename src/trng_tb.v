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

module trng_tb;

	// Inputs
	reg i_reset;
	reg [4:0] i_src_init_val;
	reg i_clk;
	reg i_read;

	// Outputs
	wire [7:0] o_dat;
	wire o_valid;
	wire [4:0] o_sampled;

	// Instantiate the Unit Under Test (UUT)
	async_trng uut (
		.i_reset(i_reset), 
		.i_src_init_val(i_src_init_val), 
		.i_clk(i_clk), 
		.i_read(i_read), 
		.o_dat(o_dat), 
		.o_valid(o_valid), 
		.o_sampled(o_sampled)
	);

	always @(posedge i_clk) begin
		if(o_valid) i_read <= 1'b1;
		else i_read <= 1'b0;
	end

	initial begin
		// Initialize Inputs
		i_reset = 1;
		i_src_init_val = 5'b01011;
		
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

