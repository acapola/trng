module ring_stage_impl(
	input wire i_reset,
	input wire i_init_val,
	input wire i_f,
	input wire i_r,
	output wire o_c
	);
wire LO,O;
wire #7 LOd = LO;
wire #11 Od = O;
assign o_c = Od;
LUT5_D #(
//i_reset     1111 1111 1111 1111   0000 0000 0000 0000 
//i_init_val  1111 1111 0000 0000   1111 1111 0000 0000   
//LO          1111 0000 1111 0000   1111 0000 1111 0000   
//i_r         1100 1100 1100 1100   1100 1100 1100 1100
//i_f         1010 1010 1010 1010   1010 1010 1010 1010   
	.INIT(32'b1111_1111_0000_0000___1011_0010_1011_0010) // Specify LUT Contents
) LUT5_D_inst (
.LO(LO), // LUT local output
.O(O), // LUT general output
.I0(i_f), // LUT input
.I1(i_r), // LUT input
.I2(LOd), // LUT input
.I3(i_init_val), // LUT input
.I4(i_reset) // LUT input
);	
endmodule
