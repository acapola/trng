
module preserved_inverter( input wire i_dat, output wire o_dat) /* synthesis syn_preserve = 1 */;
localparam LUT_INIT = 16'b0000_0000___1111_1111;
SB_LUT4 #(.LUT_INIT(LUT_INIT)) u_preserved_inverter_impl (
.O(o_dat), // LUT general output
.I0(i_dat), // LUT input
.I1(i_dat), // LUT input
.I2(i_dat), // LUT input
.I3(i_dat) // LUT input
);	
endmodule

module preserved_delay( input wire i_dat, output wire o_dat) /* synthesis syn_preserve = 1 */;
wire inverted;
preserved_inverter u_chao_osc_clock_gen_impl (.i_dat(i_dat), .o_dat(inverted));
preserved_inverter u_chao_osc_clock_gen_impl (.i_dat(inverted), .o_dat(o_dat));
endmodule

module sr_ff_edge_triggered(
	input wire i_reset,
	input wire i_s,
	input wire i_r,
	input wire );
wire sr_clk = i_s ^ i_r;
wire safe_sr_clk;//delayed clock to avoid potential metastability (not clear if that would make things better or worse, assume worse for now.
preserved_inverter u_preserved_delay (.i_dat(sr_clk), .o_dat(safe_sr_clk));
always @(posedge safe_sr_clk) osc_sel <= chao_clk;

endmodule

module chao_osc_clock_gen (output reg o_clk) /* synthesis syn_preserve = 1 */ ;
/*always @(*) begin: CHAO_OSC_CLK_GEN
	#250 o_clk = ~o_clk;//combinational loop here is intentional
end*/
wire O;
wire #11 Od = O;
assign o_clk = Od;
preserved_inverter u_chao_osc_clock_gen_impl (.i_dat(Od), .o_dat(O));
endmodule

module chao_osc (
	input wire i_reset, 
	input wire i_en, 
	input wire i_osc_sel,	//switch between slow and fast oscillations (but we don't know what level select which one until we look at post layout annotated netlist)
	output reg o_clk		//chao clock
	) /* synthesis syn_preserve = 1 */ ;
wire clk;//regular clock
reg [1:0] cnt;
always @(posedge clk) begin
	if(i_reset) begin	
		o_clk <= 1'b0;
		cnt <= 2'b00;
	end else if(i_en) begin
		cnt <= cnt + 1'b1;
	end
end
always @* o_clk = cnt[i_osc_sel];//a rather robust way to guarantee k=2
endmodule

module chao_entropy_extractor(
	input wire i_reset,
	input wire i_clk,
	input wire i_en,
	input wire i_chao_clk,
	input wire i_osc_sel,
	output reg [3:0] o_dat,
	output reg o_valid
	);
reg [1:0] ref_cnt;	
always @(posedge i_clk) begin
	if(i_reset) ref_cnt <= 2'b00;
	else if(i_en) ref_cnt <= ref_cnt + 1'b1;
end

reg [1:0] chao_cnt;
always @(posedge chao_clk) begin
	if(i_reset) chao_cnt <= 2'b00;
	else if(i_en) chao_cnt <= chao_cnt + 1'b1;
end

always @(posedge i_clk) begin
	if(i_reset) o_dat <= 4'b0000;
	else if(i_en) o_dat <= {ref_cnt,chao_cnt};
end

always @(posedge i_clk) begin
	if(i_reset) o_valid <= 1'b0;
	else if(i_en) o_valid <= i_osc_sel;
end

endmodule
	
	
module chaoentsrc #(
	parameter RNG_WIDTH = 4,
	parameter RESET = 1
	)(
	input wire i_clk,
	input wire i_reset,
	input wire i_en,
	output reg [RNG_WIDTH-1:0] o_rnd
	) /* synthesis syn_preserve = 1 */ ;

wire ff_reset = RESET & i_reset;	
reg osc_sel;
wire chao_clk;
genvar i;
generate
	for(i=0;i<RNG_WIDTH/4;i=i+1) begin: RING
		chao_osc u_osc(.i_reset(ff_reset), .i_en(i_en), .i_osc_sel(osc_sel), .o_clk(chao_clk));
	end
endgenerate


wire sr_clk = i_clk ^ chao_clk;
wire safe_sr_clk;//delayed clock to avoid potential metastability (not clear if that would make things better or worse, assume worse for now.
preserved_inverter u_preserved_delay (.i_dat(sr_clk), .o_dat(safe_sr_clk));
always @(posedge safe_sr_clk) osc_sel <= chao_clk;

chao_entropy_extractor u_chao_entropy_extractor(
	.i_reset(i_reset),
	.i_clk(i_clk),
	.i_en(i_en),
	.i_chao_clk(chao_clk),
	.i_osc_sel(osc_sel),
	.o_dat(,
	.o_valid
	);


endmodule