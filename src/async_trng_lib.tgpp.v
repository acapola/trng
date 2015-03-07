``
proc async_ring_module { name WIDTH {init_value [list]} } {
	set init_input [expr [llength $init_value]==0]
	#/* synthesis syn_keep = 1 */
``
module `$name`(
	input wire i_reset,
``if {$init_input} {``
	input wire [`$WIDTH`-1:0] i_init_val,
``}``
	output wire [`$WIDTH`-1:0] o_dat
	);
	
reg [`$WIDTH`-1:0] f_FP;
reg [`$WIDTH`-1:0] r_FP;	
``for {set i 0} {$i<$WIDTH} {incr i} {
	if {$init_input} {
		set initStr ""
	} else {set initStr _init[lindex $init_value $i]}
``
ring_stage`$initStr`_impl stage`$i`(.i_reset(i_reset), 
``if {$init_input} {``
	.i_init_val(i_init_val[`$i`]),
``}``
	.i_f(f_FP[`$i`]), .i_r(r_FP[`$i`]), .o_c(o_dat[`$i`]));
always @* begin:F`$i`
	f_FP[`$i`] = o_dat[`expr ($i+$WIDTH-1)%$WIDTH`];
end
always @* begin:R`$i`
	r_FP[`$i`] = o_dat[`expr ($i+1)%$WIDTH`];
end
``}``
endmodule
``
	return [::tgpp::getProcOutput]
}
proc entropy_extractor_module { {name entropy_extractor} {WIDTH 1} } {``
module `$name` #(
	parameter WIDTH = `$WIDTH`
	)(
	input wire i_clk,
	input wire [WIDTH-1:0] i_rnd_src,
	output reg [WIDTH-1:0] o_sampled,
	output reg o_rnd
);
always @(posedge i_clk) o_sampled <= i_rnd_src;
always @(posedge i_clk) o_rnd <= ^o_sampled;
endmodule
``
	return [::tgpp::getProcOutput]
}
if {0} {
///// BLACK BOX DECLARATION /////
module async_ring_ice40_loc #(
	parameter WIDTH = 7
	)(
	input wire i_reset,
	input wire i_clk,
	input wire [WIDTH-1:0] i_init_val,
	output reg [WIDTH-1:0] o_dat
	)/* synthesis syn_blackbox = 1 */ ;
endmodule
}
proc async_trng_module { name WIDTH NSRC SRC_WIDTH {init_value [list]} } {

	set init_input [expr [llength $init_value]==0]
	set SAMPLED_WIDTH [expr $NSRC*$SRC_WIDTH]
	#/* synthesis syn_hier = "hard" */
``
module `$name` (
	input wire i_reset,
``if {$init_input} {``	
	input wire [SRC_WIDTH-1:0] i_src_init_val,
``}``	
	input wire i_clk,
	input wire i_read,
	output reg [`$WIDTH`-1:0] o_dat,
	output reg o_valid,
	output wire [`$SAMPLED_WIDTH`-1:0] o_sampled
);
localparam WIDTH = `$WIDTH`;
localparam SRC_WIDTH = `$SRC_WIDTH`;
localparam SAMPLED_WIDTH = `$SAMPLED_WIDTH`;
wire raw_rnd;
wire [SAMPLED_WIDTH-1:0] rnd_src_dat;
``for {set i 0} {$i<$NSRC} {incr i} {``
async_ring u`$i`_rnd_src (.i_reset(i_reset), ``if {$init_input} {``.i_init_val(i_src_init_val), ``}``.o_dat(rnd_src_dat[`$i`*SRC_WIDTH+:SRC_WIDTH]));
``}``
entropy_extractor #(.WIDTH(SAMPLED_WIDTH)) extractor (.i_clk(i_clk), .i_rnd_src(rnd_src_dat),
	.o_sampled(o_sampled), .o_rnd(raw_rnd));
localparam CNT_WIDTH = 8;
reg [CNT_WIDTH-1:0] cnt;	
always @(posedge i_clk) begin
	if(i_reset) begin
		cnt <= {CNT_WIDTH{1'b0}};
		o_dat <= {WIDTH{1'b0}};
	end else begin
		if(i_read & o_valid) begin
			cnt <= {CNT_WIDTH{1'b0}};
			o_dat <= {{WIDTH-1{1'b0}},raw_rnd};//start a new output byte, keep them independent
		end else begin
			o_dat <= {o_dat[0+:WIDTH-1],o_dat[WIDTH-1]^raw_rnd};//the xor gather entropy in case the data is not consumed immediately
			if(~o_valid) cnt <= cnt + 1'b1;
		end
	end
end
always @* o_valid = cnt==WIDTH;
endmodule
`entropy_extractor_module`
`async_ring_module async_ring $SRC_WIDTH $init_value`
``
	return [::tgpp::getProcOutput]
}
