

module aes_data_round (
	input wire i_reset,
	input wire i_clk,
	input wire i_valid,
    input wire i_add_key,
	input wire i_shiftrows,
    input wire [127:0] i_key,
	input wire [127:0] i_dat,
	output reg [127:0] o_dat,
	output reg o_valid
	);
reg [127:0] sbox_in;
wire [127:0] sbox_out;
reg [127:0] sbox_out_reg;
reg sbox_out_valid;
always @(posedge i_clk, posedge i_reset) begin
  if(i_reset) begin
    o_valid <= 1'b0;
    sbox_in <= {128{1'b0}};
  end else begin
    if(i_add_key) begin
      sbox_out_valid <= 1'b0;
      o_valid <= i_valid;
    end else begin
      sbox_out_valid <= i_valid;
      o_valid <= sbox_out_valid;
    end
    sbox_in <= i_key ^ i_dat;
    sbox_out_reg <= sbox_out;
  end
end
wire [127:0] shiftrows_out;
wire [127:0] mixcolumns_out;
aes_sub_bytes_ref   u_aes_sub_bytes  (.i_dat(sbox_in)      , .o_dat(sbox_out));
aes_shift_rows_ref  u_aes_shift_rows (.i_dat(sbox_out_reg) , .o_dat(shiftrows_out));
aes_mix_columns_ref u_aes_mix_columns(.i_dat(shiftrows_out), .o_dat(mixcolumns_out));

always @* begin
  o_dat = mixcolumns_out;//full round by default
  if(i_add_key) o_dat = sbox_in;
  if(i_shiftrows) o_dat = shiftrows_out;
end
endmodule

module aes_serial_data_round (
    input wire i_reset,
    input wire i_clk,
    input wire i_valid,
    input wire i_add_key,
    input wire i_shiftrows,
    input wire [127:0] i_key,
    input wire [127:0] i_dat,
    output reg [127:0] o_dat,
    output reg o_valid
    );
reg [127:0] state;
reg [5:0] step;
wire [5:0] next_step = step + 1'b1;
localparam SHIFT_ROWS 		= 6'b010000;
localparam MIXCOLUMNS_ENTRY = 6'b010001;
localparam ADD_KEY = {6{1'b1}};
wire [7:0] sbox_out;
wire [127:0] shiftrows_out;
//wire [127:0] mixcolumns_out;
wire [7:0] mixcolumn_out;
reg [23:0] mixcolumn_in_buf;
reg sbox_in_valid;
wire sbox_out_valid;
always @(posedge i_clk, posedge i_reset) begin
  if(i_reset) begin
    o_valid <= 1'b0;
    state <= {128{1'b0}};
    step <= ADD_KEY;
	sbox_in_valid <= 1'b0;
  end else begin
	if(step[1:0]==2'b01) begin //end of a column
		mixcolumn_in_buf <= state[16+:24];
	end else begin
		mixcolumn_in_buf <= {state[0+:8],mixcolumn_in_buf[8+:16]};
	end
			
    case(step)
    ADD_KEY: begin
      if(i_valid) begin
        if(i_add_key) begin
          o_valid <= 1'b1;
		  sbox_in_valid <= 1'b0;
        end else begin
          o_valid <= 1'b0;
          step <= next_step;
		  sbox_in_valid <= 1'b1;
        end
        state <= i_key ^ i_dat;
      end else begin
		sbox_in_valid <= 1'b0;
	  end
    end
    SHIFT_ROWS: begin
		step <= next_step;
		state <= {shiftrows_out[0+:8],shiftrows_out[8+:120]};//not exactly shiftrow state yet (we do that to minimize the number of muxes)
		sbox_in_valid <= 1'b0;
    end
    MIXCOLUMNS_ENTRY: begin
		if(i_shiftrows) begin
			step <= ADD_KEY;
			o_valid <= 1'b1;
		end else begin
			step <= next_step;
		end
		state <= {state[0+:8],state[8+:120]};//shiftrow state is at this point.
		//mixcolumn_in_buf <= state[16+:24];//done in the mixcolumn_in_buf code before this big case switch.
	end
	default: begin//0 to 15 ->sbox, others->mixcolumns
		if(step[5:4]==3'b000) begin
			if(sbox_out_valid) begin
				state <= {sbox_out,state[8+:120]};
				step <= next_step;
			end
		end else begin
			if(step==6'b100001) begin
				step <= ADD_KEY;
				o_valid <= 1'b1;
			end else begin
				step <= next_step;
			end
			state <= {mixcolumn_out,state[8+:120]};
		end
    end  
    endcase
  end
end
aes_sbox_canright_l1 u_aes_sbox_canright_l1(.i_dat(state[0+:8]), .o_dat(sbox_out), .i_clk(i_clk), .i_valid(sbox_in_valid), .o_valid(sbox_out_valid), .i_decrypt(1'b0));
//aes_sbox_ram_l1 u_aes_sbox_ram_l1(.i_dat(state[0+:8]), .o_dat(sbox_out), .i_clk(i_clk), .i_valid(sbox_in_valid), .o_valid(sbox_out_valid));
aes_shift_rows_ref  u_aes_shift_rows       (.i_dat(state)      , .o_dat(shiftrows_out));
//aes_mix_columns_ref u_aes_mix_columns      (.i_dat(state)      , .o_dat(mixcolumns_out));
//assign mixcolumns_out = state;
wire [31:0] mixcolumn_in = {mixcolumn_in_buf,state[0+:8]};
aes_mix_column_quarter_ref u_aes_mix_column_quarter(.i_dat(mixcolumn_in), .o_dat(mixcolumn_out));
always @* o_dat = state;
endmodule
module aes_sbox_ram_l1 (
	input wire i_clk,
	input wire i_valid,
    input wire [7:0] i_dat,
    output reg [7:0] o_dat,
	output reg o_valid
    );
always @(i_clk) begin
	o_dat <= i_dat;
	o_valid <= i_valid;
end
endmodule

module aespp (
  input wire i_reset,
  input wire i_clk,
  input wire i_valid,
  input wire i_read,
  input wire [3:0] i_blocks,
  input wire [127:0] i_dat,
  output reg [127:0] o_dat,
  output reg o_input_consummed,
  output reg o_valid
);
localparam USE_SERIAL_ROUND=1;
reg [128-1:0] round_key;
wire [128-1:0] aes_round_out;
wire round_valid;
reg [3:0] round;
wire run = (i_valid | (round!=0)) & ~o_valid;
wire valid = round ==0 ? i_valid & (~o_valid|i_read) : round_valid;
wire first_round = round==0;
wire last_round = round==(9+USE_SERIAL_ROUND);
wire final_add_key = (round >=(9+USE_SERIAL_ROUND)) & round_valid;
reg [3:0] block;
wire first_block = block==0;
wire [128-1:0] aes_state = first_round ?
                              first_block ? i_dat : i_dat^aes_round_out
                            : 
                              aes_round_out;
always @* o_dat = aes_round_out;
aes_serial_data_round u_aes_data_round(
      .i_reset(i_reset),
      .i_clk(i_clk),
      .i_key(round_key),
      .i_valid(valid),
      .i_add_key(final_add_key),
      .i_shiftrows(last_round),
      .i_dat(aes_state),
      .o_dat(aes_round_out),
      .o_valid(round_valid)
);
/*always @(i_clk) begin
	aes_round_out <= {aes_state[0+:8],aes_state[8+:120]};
	round_valid <= valid ^ last_round ^ final_add_key;
end*/
always @* begin
	//round_key=128'h00000000_00000000_00000000_00000000;
  case(round)
  4'h0: round_key=128'h00000000_00000000_00000000_00000000;
  4'h1: round_key=128'h62636363_62636363_62636363_62636363;
  4'h2: round_key=128'h9B9898C9_F9FBFBAA_9B9898C9_F9FBFBAA;
  4'h3: round_key=128'h90973450_696CCFFA_F2F45733_0B0FAC99;
  4'h4: round_key=128'hEE06DA7B_876A1581_759E42B2_7E91EE2B;
  4'h5: round_key=128'h7F2E2B88_F8443E09_8DDA7CBB_F34B9290;
  4'h6: round_key=128'hEC614B85_1425758C_99FF0937_6AB49BA7;
  4'h7: round_key=128'h21751787_3550620B_ACAF6B3C_C61BF09B;
  4'h8: round_key=128'h0EF90333_3BA96138_97060A04_511DFA9F;
  4'h9: round_key=128'hB1D4D8E2_8A7DB9DA_1D7BB3DE_4C664941;
  4'hA: round_key=128'hB4EF5BCB_3E92E211_23E951CF_6F8F188E;
  default: round_key=128'hxxxxxxxx_xxxxxxxx_xxxxxxxx_xxxxxxxx;
  endcase
end

always @(posedge i_clk, posedge i_reset) begin
  if(i_reset) begin
    round <= 4'h0;
    o_valid <= 1'b0;
    block <= 0;
    o_input_consummed <= 1'b0;
  end else if(o_valid & ~i_read)begin
    //do nothing
  end else begin
    case(round) 
    4'd0: begin
      if(i_valid) begin
        round <= round +1'b1;
        o_input_consummed <= 1'b1;
      end
      o_valid <= 1'b0;
    end
    default: begin
      o_input_consummed <= 1'b0;
      if(round_valid) begin
        case(round)
        4'd10: begin
          round <= 4'h0;
          if(block==i_blocks) begin
            block <= 0;
            o_valid <= 1'b1;
          end else begin
            block <= block +1'b1;
          end
        end
        default: begin
          round <= round +1'b1;
          o_valid <= 1'b0;
        end
        endcase
      end
    end
    endcase
  end
end
endmodule
/*
module aespp_full_pipeline (
  input wire i_reset,
  input wire i_clk,
  input wire i_valid,
  input wire [127:0] i_dat,
  output reg [127:0] o_dat,
  output reg o_valid
);

wire [128*11-1:0] key_schedule = {128*11{1'b1}};
wire [10:0] valid;
wire [128*11-1:0] aes_state;
assign valid[0]=i_valid;
assign aes_state[0+:128] = i_dat;
genvar i;
generate
  for(i=0;i<10;i=i+1) begin: ROUNDS
    aes_data_round u_aes_data_round(
      .i_reset(i_reset),
      .i_clk(i_clk),
      .i_key(key_schedule[i*128+:128]),
      .i_valid(valid[i]),
      .i_mixcolumns(i!=9),
      .i_dat(aes_state[128*i+:128]),
      .o_dat(aes_state[128*(i+1)+:128]),
      .o_valid(valid[i+1])
    );
  end
endgenerate
always @(posedge i_clk, posedge i_reset) begin
  if(i_reset) begin
    o_valid <= 1'b0;
    o_dat <= {128{1'b0}};
  end else begin
    o_valid <= valid[10];
    o_dat <= aes_state[128*10+:128] ^ key_schedule[128*10+:128];
  end
end
endmodule
*/
