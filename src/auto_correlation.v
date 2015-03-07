//on the fly auto correlation, protected against overflow (new data ignored)
//the auto correlation is given for i_delta+1: i_delta=0 gives the autocorrelation for consecutive samples.
module auto_correlation #(
	parameter WIDTH = 1,
	parameter OUT_WIDTH = 32,
	parameter DELTA_WIDTH = 8
	)(
	input wire i_clk,
	input wire i_init,//one cycle pulse to start a new computation
	input wire [DELTA_WIDTH-1:0] i_delta,
	input wire [WIDTH-1:0] i_dat,
	input wire i_write,
	output reg [OUT_WIDTH-1:0] o_write_cnt,
	output reg [OUT_WIDTH-1:0] o_match_cnt,
	output reg o_full //high if it can't accept new data (o_write_cnt has its max value)
);
localparam DELAY_WIDTH = (1<<DELTA_WIDTH)*WIDTH;
reg [DELAY_WIDTH-1:0] delayed_dat;
reg [DELTA_WIDTH-1:0] delta;
wire [WIDTH-1:0] delta_dat = delayed_dat[DELAY_WIDTH-1-:WIDTH];
//always @(posedge i_clk) delta_dat <= delayed_dat[delta*WIDTH+:WIDTH];
reg [WIDTH-1:0] delta0_dat;// = delayed_dat[0+:WIDTH];
wire [OUT_WIDTH-1:0] next_write_cnt =  o_write_cnt + 1'b1;
always @* o_full = next_write_cnt=={OUT_WIDTH{1'b0}};

//must be done for every write even if we are full.
//this is because we need to keep that in sync with the data source.
//otherwise the first few counts and next computation will be wrong
reg write_l1;
reg [DELTA_WIDTH-1:0] init_cnt;
always @(posedge i_clk) begin: DELAY
	integer i;
	write_l1 <= i_write;
	//init_l1 <= i_init;
	if(i_write) begin
		delta0_dat <= i_dat;
		delayed_dat[0*WIDTH+:WIDTH] <= delta0_dat;
		for(i=1;i<DELAY_WIDTH;i=i+1) begin
			delayed_dat[i*WIDTH+:WIDTH] <= delta==(DELAY_WIDTH-i-1) ? delta0_dat : delayed_dat[(i-1)*WIDTH+:WIDTH];
		end
	end
end

always @(posedge i_clk) begin
	if(i_init) begin
		o_write_cnt <= {OUT_WIDTH{1'b0}};
		o_match_cnt <= {OUT_WIDTH{1'b0}};
		delta <= i_delta;
		init_cnt <= 0;
	end else if((init_cnt==delta+1'b1) & write_l1 & ~o_full) begin
		o_write_cnt <= o_write_cnt + 1'b1;
		if(delta0_dat==delta_dat) o_match_cnt <= o_match_cnt + 1'b1;
	end else init_cnt <= init_cnt + 1'b1;
end	
endmodule

/*
module auto_correlation_slow #(
	parameter WIDTH = 1,
	parameter OUT_WIDTH = 32,
	parameter DELTA_WIDTH = 8
	)(
	input wire i_clk,
	input wire i_init,//one cycle pulse to start a new computation
	input wire [DELTA_WIDTH-1:0] i_delta,
	input wire [WIDTH-1:0] i_dat,
	input wire i_write,
	output reg [OUT_WIDTH-1:0] o_write_cnt,
	output reg [OUT_WIDTH-1:0] o_match_cnt,
	output reg o_full //high if it can't accept new data (o_write_cnt has its max value)
);
localparam DELAY_WIDTH = (1<<DELTA_WIDTH)*WIDTH;
reg [DELAY_WIDTH-1:0] delayed_dat;
reg [DELTA_WIDTH-1:0] delta;
reg [WIDTH-1:0] delta_dat;
always @(posedge i_clk) delta_dat <= delayed_dat[delta*WIDTH+:WIDTH];
wire [WIDTH-1:0] delta0_dat = delayed_dat[0+:WIDTH];
wire [OUT_WIDTH-1:0] next_write_cnt =  o_write_cnt + 1'b1;
always @* o_full = next_write_cnt=={OUT_WIDTH{1'b0}};

//must be done for every write even if we are full.
//this is because we need to keep that in sync with the data source.
//otherwise the first few counts and next computation will be wrong
reg write_l1;
reg init_l1;
always @(posedge i_clk) begin
	write_l1 <= i_write;
	init_l1 <= i_init;
	if(i_write) delayed_dat <= {delayed_dat[0+:DELAY_WIDTH-WIDTH],i_dat};
end

always @(posedge i_clk) begin
	if(i_init) begin
		o_write_cnt <= {OUT_WIDTH{1'b0}};
		o_match_cnt <= {OUT_WIDTH{1'b0}};
		delta <= i_delta;
	end else if(~init_l1 & write_l1 & ~o_full) begin
		o_write_cnt <= o_write_cnt + 1'b1;
		if(delta0_dat==delta_dat) o_match_cnt <= o_match_cnt + 1'b1;
	end
end	
endmodule
*/