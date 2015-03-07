``
proc fifo_module { name inWidth outWidth } {
	set outputBuf [expr $inWidth > $outWidth]
``
module `$name` #(
	parameter DEPTH_WIDTH = 10,
	//fixed parameters
	parameter OUT_WIDTH = `$outWidth`,
	parameter IN_WIDTH = `$inWidth`
	)(
	input wire i_reset,
	input wire i_clk,
	input wire i_write,
	input wire i_read,
	input wire [IN_WIDTH-1:0] i_dat,
	output reg [OUT_WIDTH-1:0] o_dat,
	output reg o_almost_empty,//can read one more time
	output reg o_empty,//cant read
	output reg o_almost_full,//can write one more time
	output reg o_full//can't write
	);
localparam DEPTH = 1 << DEPTH_WIDTH;
//assume a RAM for implementation of storage => don't use shift reg structure, use addresses	
reg [IN_WIDTH-1:0] storage[DEPTH-1:0];
reg [DEPTH_WIDTH-1:0] write_addr;
reg [DEPTH_WIDTH-1:0] read_addr;
wire [DEPTH_WIDTH-1:0] next_write_addr = write_addr + 1'b1;
wire [DEPTH_WIDTH-1:0] next_read_addr = read_addr + 1'b1;
``if $outputBuf {``
localparam OUT_PER_WORD = IN_WIDTH / OUT_WIDTH;
reg [IN_WIDTH-1:0] out_buf;
reg [OUT_PER_WORD-1:0] out_read_cnt;//way bigger than needed
always @* o_dat = out_buf[0+:OUT_WIDTH];
``} else {``
always @* o_almost_empty = next_read_addr == write_addr;
``}``
always @* o_almost_full = next_write_addr == read_addr;
always @(posedge i_clk) begin
	if(i_reset) begin
		``if $outputBuf {``
		o_almost_empty <= 1'b0;
		out_read_cnt <= OUT_PER_WORD-1;
		``}``
		o_full <= 1'b0;
		o_empty <= 1'b1;
		write_addr <= {DEPTH_WIDTH{1'b0}};
		read_addr <= {DEPTH_WIDTH{1'b0}};
	end else begin
		if(i_write & ~o_full) begin
			o_empty <= 1'b0;
			``if $outputBuf {``
			o_almost_empty <= 1'b0;
			``}``
			o_full <= o_almost_full;
			write_addr <= next_write_addr;
			storage[write_addr] <= i_dat;
		end else if(i_read & ~o_empty) begin //priority to write, allow to use single port RAMs
``if $outputBuf {``
			if(out_read_cnt==OUT_PER_WORD-1) begin
				out_read_cnt <= 0;
				o_almost_empty <= 1'b0;
				o_empty <= o_almost_empty;
				o_full <= 1'b0;
				read_addr <= next_read_addr;
				out_buf <= storage[read_addr];
			end else begin
				out_read_cnt <= out_read_cnt + 1'b1;
				o_almost_empty <= (out_read_cnt == OUT_PER_WORD-2) & (next_read_addr == write_addr);
				out_buf <= {{OUT_WIDTH{1'bx}},out_buf[OUT_WIDTH+:OUT_WIDTH*OUT_PER_WORD]};
			end
``} else {``
			o_empty <= o_almost_empty;
			o_full <= 1'b0;
			read_addr <= next_read_addr;
			o_dat <= storage[read_addr];
``}``
		end
	end
end
endmodule

``
	return [tgpp::getProcOutput]
}

