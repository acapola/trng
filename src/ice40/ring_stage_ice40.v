module ring_stage_init0_impl(
	input wire i_reset,
	input wire i_f,
	input wire i_r,
	output wire o_c
	);
wire O;
wire #11 Od = O;
assign o_c = Od;
//i_reset                 1111 1111   0000 0000 
//LO                      1111 0000   1111 0000   
//i_r                     1100 1100   1100 1100
//i_f                     1010 1010   1010 1010   
localparam LUT_INIT = 16'b0000_0000___1011_0010;
SB_LUT4 #(.LUT_INIT(LUT_INIT)) u_0 (
.O(O), // LUT general output
.I0(i_f), // LUT input
.I1(i_r), // LUT input
.I2(Od), // LUT input
.I3(i_reset) // LUT input
);	
endmodule

module ring_stage_init1_impl(
	input wire i_reset,
	input wire i_f,
	input wire i_r,
	output wire o_c
	);
wire O;
wire #11 Od = O;
assign o_c = Od;
SB_LUT4 #(
//i_reset     1111 1111   0000 0000 
//LO          1111 0000   1111 0000   
//i_r         1100 1100   1100 1100
//i_f         1010 1010   1010 1010   
	.LUT_INIT(16'b1111_1111___1011_0010) // Specify LUT Contents
) LUT4_inst (
.O(O), // LUT general output
.I0(i_f), // LUT input
.I1(i_r), // LUT input
.I2(Od), // LUT input
.I3(i_reset) // LUT input
);	
endmodule


module ring_stage_impl(
	input wire i_reset,
	input wire i_init_val,
	input wire i_f,
	input wire i_r,
	output wire o_c
	);
wire O;
wire #11 Od = O;
assign o_c = Od;
LUT5 #(
//i_reset     1111 1111 1111 1111   0000 0000 0000 0000 
//i_init_val  1111 1111 0000 0000   1111 1111 0000 0000   
//LO          1111 0000 1111 0000   1111 0000 1111 0000   
//i_r         1100 1100 1100 1100   1100 1100 1100 1100
//i_f         1010 1010 1010 1010   1010 1010 1010 1010   
	.INIT(32'b1111_1111_0000_0000___1011_0010_1011_0010) // Specify LUT Contents
) LUT5_inst (
.O(O), // LUT general output
.I0(i_f), // LUT input
.I1(i_r), // LUT input
.I2(Od), // LUT input
.I3(i_init_val), // LUT input
.I4(i_reset) // LUT input
);	
endmodule

module LUT5 #(
	parameter INIT = 32'h0000_0000
)(
	input wire I0,
	input wire I1,
	input wire I2,
	input wire I3,
	input wire I4,
	output wire O
);
wire O0,O1;
SB_LUT4 #(.LUT_INIT(INIT[ 0+:16])) u_0 (
.O (O0), // output
.I0 (I0), // data input 0
.I1 (I1), // data input 1
.I2 (I2), // data input 2
.I3 (I3) // data input 3
);
SB_LUT4 #(.LUT_INIT(INIT[16+:16])) u_1 (
.O (O1), // output
.I0 (I0), // data input 0
.I1 (I1), // data input 1
.I2 (I2), // data input 2
.I3 (I3) // data input 3
);
assign O = I4 ? O1 : O0;
endmodule