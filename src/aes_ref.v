
`default_nettype none

module aes_mix_columns_ref(
    input wire [127:0] i_dat,
    output wire [127:0] o_dat
    );
aes_mix_column_ref mix_column0(.i_dat(i_dat[127:96]), .o_dat(o_dat[127:96]));
aes_mix_column_ref mix_column1(.i_dat(i_dat[ 95:64]), .o_dat(o_dat[ 95:64]));
aes_mix_column_ref mix_column2(.i_dat(i_dat[ 63:32]), .o_dat(o_dat[ 63:32]));
aes_mix_column_ref mix_column3(.i_dat(i_dat[ 31: 0]), .o_dat(o_dat[ 31: 0]));
endmodule

module aes_mix_column_ref(
    input wire [31:0] i_dat,
    output reg [31:0] o_dat
    );
    
function [7:0] xtime;
    input [7:0] b; xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction

wire [7:0] s0 = i_dat[24+:8];
wire [7:0] s1 = i_dat[16+:8];
wire [7:0] s2 = i_dat[ 8+:8];
wire [7:0] s3 = i_dat[ 0+:8];
always @* o_dat[31:24]=xtime(s0)^xtime(s1)^s1^s2^s3;
always @* o_dat[23:16]=s0^xtime(s1)^xtime(s2)^s2^s3;
always @* o_dat[15: 8]=s0^s1^xtime(s2)^xtime(s3)^s3;
always @* o_dat[ 7: 0]=xtime(s0)^s0^s1^s2^xtime(s3);
endmodule

module aes_mix_column_quarter_ref(
    input wire [31:0] i_dat,
    output reg [7:0] o_dat
    );
    
function [7:0] xtime;
    input [7:0] b; xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction

wire [7:0] s0 = i_dat[24+:8];
wire [7:0] s1 = i_dat[16+:8];
wire [7:0] s2 = i_dat[ 8+:8];
wire [7:0] s3 = i_dat[ 0+:8];
always @* o_dat[ 7: 0]=xtime(s0)^s0^s1^s2^xtime(s3);
endmodule

module aes_inv_mix_columns_ref(
    input wire [127:0] i_dat,
    output wire [127:0] o_dat
    );
aes_inv_mix_column_ref mix_column0(.i_dat(i_dat[127:96]), .o_dat(o_dat[127:96]));
aes_inv_mix_column_ref mix_column1(.i_dat(i_dat[ 95:64]), .o_dat(o_dat[ 95:64]));
aes_inv_mix_column_ref mix_column2(.i_dat(i_dat[ 63:32]), .o_dat(o_dat[ 63:32]));
aes_inv_mix_column_ref mix_column3(.i_dat(i_dat[ 31: 0]), .o_dat(o_dat[ 31: 0]));
endmodule

module aes_inv_mix_column_ref(
    input wire [31:0] i_dat,
    output reg [31:0] o_dat
    );
    
function [7:0] xtime;
    input [7:0] b; xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction
function [7:0] xtime_4;
    input [7:0] b; xtime_4 = xtime(xtime(b));
endfunction
function [7:0] xtime_8;
    input [7:0] b; xtime_8 = xtime(xtime_4(b));
endfunction
function [7:0] xtime_9;
    input [7:0] b; xtime_9 = xtime_8(b)^b;
endfunction
function [7:0] xtime_b;
    input [7:0] b; xtime_b = xtime_9(b) ^ xtime(b);
endfunction
function [7:0] xtime_d;
    input [7:0] b; xtime_d = xtime_9(b) ^ xtime_4(b);
endfunction
function [7:0] xtime_e;//1110 -> 8+4+2
    input [7:0] b; xtime_e = xtime_8(b) ^ xtime_4(b) ^ xtime(b);
endfunction

wire [7:0] s0 = i_dat[24+:8];
wire [7:0] s1 = i_dat[16+:8];
wire [7:0] s2 = i_dat[ 8+:8];
wire [7:0] s3 = i_dat[ 0+:8];

always @* o_dat[31:24]=xtime_e(s0)^xtime_b(s1)^xtime_d(s2)^xtime_9(s3);
always @* o_dat[23:16]=xtime_9(s0)^xtime_e(s1)^xtime_b(s2)^xtime_d(s3);
always @* o_dat[15: 8]=xtime_d(s0)^xtime_9(s1)^xtime_e(s2)^xtime_b(s3);
always @* o_dat[ 7: 0]=xtime_b(s0)^xtime_d(s1)^xtime_9(s2)^xtime_e(s3);
endmodule

module aes_shift_rows_ref(
    input wire [127:0] i_dat,
    output reg [127:0] o_dat
    );    
always @* o_dat[127:96] = {i_dat[127:120], i_dat[ 87: 80], i_dat[ 47: 40], i_dat[  7: 0]};
always @* o_dat[ 95:64] = {i_dat[ 95: 88], i_dat[ 55: 48], i_dat[ 15:  8], i_dat[103:96]};
always @* o_dat[ 63:32] = {i_dat[ 63: 56], i_dat[ 23: 16], i_dat[111:104], i_dat[ 71:64]};
always @* o_dat[ 31: 0] = {i_dat[ 31: 24], i_dat[119:112], i_dat[ 79: 72], i_dat[ 39:32]};
endmodule

module aes_inv_shift_rows_ref(
    input wire [127:0] i_dat,
    output reg [127:0] o_dat
    );    
always @* o_dat[127:96] = {i_dat[127:120], i_dat[ 23: 16], i_dat[ 47: 40], i_dat[ 71:64]};
always @* o_dat[ 95:64] = {i_dat[ 95: 88], i_dat[119:112], i_dat[ 15:  8], i_dat[ 39:32]};
always @* o_dat[ 63:32] = {i_dat[ 63: 56], i_dat[ 87: 80], i_dat[111:104], i_dat[  7: 0]};
always @* o_dat[ 31: 0] = {i_dat[ 31: 24], i_dat[ 55: 48], i_dat[ 79: 72], i_dat[103:96]};
endmodule

module aes_sub_bytes_ref(
    input wire [127:0] i_dat,
    output wire [127:0] o_dat
    );
genvar i;
generate
for (i=0;i<16;i=i+1) begin : sbox_block
   aes_sbox_canright u_sbox (
      .i_dat(i_dat[i*8+7:i*8]),
      .i_decrypt(1'b0),
      .o_dat(o_dat[i*8+7:i*8])
   );
end
endgenerate
endmodule

module aes_sub_bytes_enc_dec_ref(
    input wire [127:0] i_dat,
    input wire i_decrypt,
    output wire [127:0] o_dat
    );
genvar i;
generate
for (i=0;i<16;i=i+1) begin : sbox_block
   aes_enc_dec_sbox_ref u_sbox (
      .i_dat(i_dat[i*8+7:i*8]),
      .i_decrypt(i_decrypt),
      .o_dat(o_dat[i*8+7:i*8])
   );
end
endgenerate
endmodule

module aes_enc_dec_sbox_ref(
    input wire [7:0] i_dat,
    input wire i_decrypt,
    output reg [7:0] o_dat
    );
wire [7:0] first_matrix_out,first_matrix_in,last_matrix_out_enc,last_matrix_out_dec;
wire [3:0] p,q,p2,q2,sumpq,sump2q2,inv_sump2q2,p_new,q_new,mulpq,q2B;
reg [7:0]  first_matrix_out_L;
reg [3:0]  p_new_L,q_new_L;    

wire ende = i_decrypt;//encryption
wire [7:0] en_dout;//encryption result
wire [7:0] de_dout;//decryption result
// GF(256) to GF(16) transformation
assign first_matrix_in[7:0] = ende ? INV_AFFINE(i_dat[7:0]): i_dat[7:0];
always @* first_matrix_out_L[7:0] = GF256_TO_GF16(first_matrix_in[7:0]);
       
/*****************************************************************************/
// GF16 inverse logic
/*****************************************************************************/
//                     p+q _____ 
//                              \
//  p --> p2 ___                 \
//   \          \                 x --> p_new
//    x -> p*q -- + --> inverse -/
//   /          /                \
//  q --> q2*B-/                  x --> q_new 
//   \___________________________/
//
assign p[3:0] = first_matrix_out_L[3:0];
assign q[3:0] = first_matrix_out_L[7:4];
assign p2[3:0] = SQUARE(p[3:0]);
assign q2[3:0] = SQUARE(q[3:0]);
//p+q
assign sumpq[3:0] = p[3:0] ^ q[3:0];
//p*q
assign mulpq[3:0] = MUL(p[3:0],q[3:0]);
//q2B calculation
assign q2B[0]=q2[1]^q2[2]^q2[3];
assign q2B[1]=q2[0]^q2[1];
assign q2B[2]=q2[0]^q2[1]^q2[2];
assign q2B[3]=q2[0]^q2[1]^q2[2]^q2[3];
//p2+p*q+q2B
assign sump2q2[3:0] = q2B[3:0] ^ mulpq[3:0] ^ p2[3:0];
// inverse p2+pq+q2B
assign inv_sump2q2[3:0] = INVERSE(sump2q2[3:0]);
// results
always @* p_new_L[3:0] = MUL(sumpq[3:0],inv_sump2q2[3:0]);
always @* q_new_L[3:0] = MUL(q[3:0],inv_sump2q2[3:0]);
        
// GF(16) to GF(256) transformation
assign last_matrix_out_dec[7:0] = GF16_TO_GF256(p_new_L[3:0],q_new_L[3:0]);
assign last_matrix_out_enc[7:0] = AFFINE(last_matrix_out_dec[7:0]);
assign en_dout[7:0] = last_matrix_out_enc[7:0];
assign de_dout[7:0] = last_matrix_out_dec[7:0];   

always @* o_dat = i_decrypt ? de_dout : en_dout;    
/*****************************************************************************/
// Functions
/*****************************************************************************/
 
// convert GF(256) to GF(16)
function [7:0] GF256_TO_GF16;
input [7:0] data;
reg a,b,c;
begin
	a = data[1]^data[7];
	b = data[5]^data[7];
	c = data[4]^data[6];
	GF256_TO_GF16[0] = c^data[0]^data[5];
	GF256_TO_GF16[1] = data[1]^data[2];
	GF256_TO_GF16[2] = a;
	GF256_TO_GF16[3] = data[2]^data[4];
	GF256_TO_GF16[4] = c^data[5]; 
	GF256_TO_GF16[5] = a^c;
	GF256_TO_GF16[6] = b^data[2]^data[3];
	GF256_TO_GF16[7] = b;
end
endfunction
 
// squre 
function [3:0] SQUARE;
input [3:0] data;
begin
	SQUARE[0] = data[0]^data[2];
	SQUARE[1] = data[2];
	SQUARE[2] = data[1]^data[3];
	SQUARE[3] = data[3];
end
endfunction
 
// inverse
function [3:0] INVERSE;
input [3:0] data;
reg a;
begin
	a=data[1]^data[2]^data[3]^(data[1]&data[2]&data[3]);
	INVERSE[0]=a^data[0]^(data[0]&data[2])^(data[1]&data[2])^(data[0]&data[1]&data[2]);
	INVERSE[1]=(data[0]&data[1])^(data[0]&data[2])^(data[1]&data[2])^data[3]^
		(data[1]&data[3])^(data[0]&data[1]&data[3]);
	INVERSE[2]=(data[0]&data[1])^data[2]^(data[0]&data[2])^data[3]^
		(data[0]&data[3])^(data[0]&data[2]&data[3]);
	INVERSE[3]=a^(data[0]&data[3])^(data[1]&data[3])^(data[2]&data[3]);
end
endfunction
 
// multiply
function [3:0] MUL;
input [3:0] d1,d2;
reg a,b;
begin
	a=d1[0]^d1[3];
	b=d1[2]^d1[3];
 
	MUL[0]=(d1[0]&d2[0])^(d1[3]&d2[1])^(d1[2]&d2[2])^(d1[1]&d2[3]);
	MUL[1]=(d1[1]&d2[0])^(a&d2[1])^(b&d2[2])^((d1[1]^d1[2])&d2[3]);
	MUL[2]=(d1[2]&d2[0])^(d1[1]&d2[1])^(a&d2[2])^(b&d2[3]);
	MUL[3]=(d1[3]&d2[0])^(d1[2]&d2[1])^(d1[1]&d2[2])^(a&d2[3]);
end
endfunction
 
// GF16 to GF256 transform
function [7:0] GF16_TO_GF256;
input [3:0] p,q;
reg a,b;
begin
	a=p[1]^q[3];
	b=q[0]^q[1];
 
	GF16_TO_GF256[0]=p[0]^q[0];
	GF16_TO_GF256[1]=b^q[3];
	GF16_TO_GF256[2]=a^b;
	GF16_TO_GF256[3]=b^p[1]^q[2];
	GF16_TO_GF256[4]=a^b^p[3];
	GF16_TO_GF256[5]=b^p[2];
	GF16_TO_GF256[6]=a^p[2]^p[3]^q[0];
	GF16_TO_GF256[7]=b^p[2]^q[3];
end
endfunction
 
// affine transformation
function [7:0] AFFINE;
input [7:0] data;
begin
	//affine trasformation
	AFFINE[0]=(!data[0])^data[4]^data[5]^data[6]^data[7];
	AFFINE[1]=(!data[0])^data[1]^data[5]^data[6]^data[7];
	AFFINE[2]=data[0]^data[1]^data[2]^data[6]^data[7];
	AFFINE[3]=data[0]^data[1]^data[2]^data[3]^data[7];
	AFFINE[4]=data[0]^data[1]^data[2]^data[3]^data[4];
	AFFINE[5]=(!data[1])^data[2]^data[3]^data[4]^data[5];
	AFFINE[6]=(!data[2])^data[3]^data[4]^data[5]^data[6];
	AFFINE[7]=data[3]^data[4]^data[5]^data[6]^data[7];
end
endfunction
 
// inverse affine transformation
function [7:0] INV_AFFINE;
input [7:0] data;
reg a,b,c,d;
begin
	a=data[0]^data[5];
	b=data[1]^data[4];
	c=data[2]^data[7];
	d=data[3]^data[6];
	INV_AFFINE[0]=(!data[5])^c;
	INV_AFFINE[1]=data[0]^d;
	INV_AFFINE[2]=(!data[7])^b;
	INV_AFFINE[3]=data[2]^a;
	INV_AFFINE[4]=data[1]^d;
	INV_AFFINE[5]=data[4]^c;
	INV_AFFINE[6]=data[3]^a;
	INV_AFFINE[7]=data[6]^b;
end
endfunction
endmodule    
`default_nettype wire 

`default_nettype wire
/* S-box using all normal bases */
/* case # 4 : [d^16, d], [alpha^8, alpha^2], [Omega^2, Omega] */
/* beta^8 = N^2*alpha^2, N = w^2 */
/* optimized using OR gates and NAND gates */
/* square in GF(2^2), using normal basis [Omega^2,Omega] */
/* inverse is the same as square in GF(2^2), using any normal basis */
module GF_SQ_2 ( A, Q );
input [1:0] A;
output [1:0] Q;
assign Q = { A[0], A[1] };
endmodule
/* scale by w = Omega in GF(2^2), using normal basis [Omega^2,Omega] */
module GF_SCLW_2 ( A, Q );
input [1:0] A;
output [1:0] Q;
assign Q = { (A[1] ^ A[0]), A[1] };
endmodule
/* scale by w^2 = Omega^2 in GF(2^2), using normal basis [Omega^2,Omega] */
module GF_SCLW2_2 ( A, Q );
input [1:0] A;
output [1:0] Q;
assign Q = { A[0], (A[1] ^ A[0]) };
endmodule
/* multiply in GF(2^2), shared factors, using normal basis [Omega^2,Omega] */
module GF_MULS_2 ( A, ab, B, cd, Q );
input [1:0] A;
input ab;
input [1:0] B;
input cd;
output [1:0] Q;
wire abcd, p, q;
assign abcd = ~(ab & cd); /* note: ~& syntax for NAND won?t compile */
assign p = (~(A[1] & B[1])) ^ abcd;
assign q = (~(A[0] & B[0])) ^ abcd;
assign Q = { p, q };
endmodule
/* multiply & scale by N in GF(2^2), shared factors, basis [Omega^2,Omega] */
module GF_MULS_SCL_2 ( A, ab, B, cd, Q );
input [1:0] A;
input ab;
input [1:0] B;
input cd;
output [1:0] Q;
wire t, p, q;
assign t = ~(A[0] & B[0]); /* note: ~& syntax for NAND won?t compile */
assign p = (~(ab & cd)) ^ t;
assign q = (~(A[1] & B[1])) ^ t;
assign Q = { p, q };
endmodule
/* inverse in GF(2^4)/GF(2^2), using normal basis [alpha^8, alpha^2] */
module GF_INV_4 ( A, Q );
input [3:0] A;
output [3:0] Q;
wire [1:0] a, b, c, d, p, q;
wire sa, sb, sd; /* for shared factors in multipliers */
assign a = A[3:2];
assign b = A[1:0];
assign sa = a[1] ^ a[0];
assign sb = b[1] ^ b[0];
/* optimize this section as shown below
GF_MULS_2 abmul(a, sa, b, sb, ab);
GF_SQ_2 absq( (a ^ b), ab2);
GF_SCLW2_2 absclN( ab2, ab2N);
GF_SQ_2 dinv( (ab ^ ab2N), d);
*/
assign c = { /* note: ~| syntax for NOR won?t compile */
~(a[1] | b[1]) ^ (~(sa & sb)) ,
~(sa | sb) ^ (~(a[0] & b[0])) };
GF_SQ_2 dinv( c, d);
/* end of optimization */
assign sd = d[1] ^ d[0];
GF_MULS_2 pmul(d, sd, b, sb, p);
GF_MULS_2 qmul(d, sd, a, sa, q);
assign Q = { p, q };
endmodule
/* square & scale by nu in GF(2^4)/GF(2^2), normal basis [alpha^8, alpha^2] */
/* nu = beta^8 = N^2*alpha^2, N = w^2 */
module GF_SQ_SCL_4 ( A, Q );
input [3:0] A;
output [3:0] Q;
wire [1:0] a, b, ab2, b2, b2N2;
assign a = A[3:2];
assign b = A[1:0];
GF_SQ_2 absq(a ^ b,ab2);
GF_SQ_2 bsq(b,b2);
GF_SCLW_2 bmulN2(b2,b2N2);
assign Q = { ab2, b2N2 };
endmodule
/* multiply in GF(2^4)/GF(2^2), shared factors, basis [alpha^8, alpha^2] */
module GF_MULS_4 ( A, a, Al, Ah, aa, B, b, Bl, Bh, bb, Q );
input [3:0] A;
input [1:0] a;
input Al;
input Ah;
input aa;
input [3:0] B;
input [1:0] b;
input Bl;
input Bh;
input bb;
output [3:0] Q;
wire [1:0] ph, pl, ps, p;
wire t;
GF_MULS_2 himul(A[3:2], Ah, B[3:2], Bh, ph);
GF_MULS_2 lomul(A[1:0], Al, B[1:0], Bl, pl);
GF_MULS_SCL_2 summul( a, aa, b, bb, p);
assign Q = { (ph ^ p), (pl ^ p) };
endmodule
/* inverse in GF(2^8)/GF(2^4), using normal basis [d^16, d] */
module GF_INV_8 ( A, Q );
input [7:0] A;
output [7:0] Q;
wire [3:0] a, b, c, d, p, q;
wire [1:0] sa, sb, sd, t; /* for shared factors in multipliers */
wire al, ah, aa, bl, bh, bb, dl, dh, dd; /* for shared factors */
wire c1, c2, c3; /* for temp var */
assign a = A[7:4];
assign b = A[3:0];
assign sa = a[3:2] ^ a[1:0];
assign sb = b[3:2] ^ b[1:0];
assign al = a[1] ^ a[0];
assign ah = a[3] ^ a[2];
assign aa = sa[1] ^ sa[0];
assign bl = b[1] ^ b[0];
assign bh = b[3] ^ b[2];
assign bb = sb[1] ^ sb[0];
/* optimize this section as shown below
GF_MULS_4 abmul(a, sa, al, ah, aa, b, sb, bl, bh, bb, ab);
GF_SQ_SCL_4 absq( (a ^ b), ab2);
GF_INV_4 dinv( (ab ^ ab2), d);
*/
assign c1 = ~(ah & bh);
assign c2 = ~(sa[0] & sb[0]);
assign c3 = ~(aa & bb);
assign c = { /* note: ~| syntax for NOR won?t compile */
(~(sa[0] | sb[0]) ^ (~(a[3] & b[3]))) ^ c1 ^ c3 ,
(~(sa[1] | sb[1]) ^ (~(a[2] & b[2]))) ^ c1 ^ c2 ,
(~(al | bl) ^ (~(a[1] & b[1]))) ^ c2 ^ c3 ,
(~(a[0] | b[0]) ^ (~(al & bl))) ^ (~(sa[1] & sb[1])) ^ c2 };
GF_INV_4 dinv( c, d);
/* end of optimization */
assign sd = d[3:2] ^ d[1:0];
assign dl = d[1] ^ d[0];
assign dh = d[3] ^ d[2];
assign dd = sd[1] ^ sd[0];
GF_MULS_4 pmul(d, sd, dl, dh, dd, b, sb, bl, bh, bb, p);
GF_MULS_4 qmul(d, sd, dl, dh, dd, a, sa, al, ah, aa, q);
assign Q = { p, q };
endmodule
/* inverse in GF(2^8)/GF(2^4), using normal basis [d^16, d] */
module GF_INV_8_l1 (
	input wire i_clk, 
	input wire [7:0] A,
	output wire [7:0] Q
	);
wire [3:0] a, b, c, d;
wire [1:0] sa, sb; /* for shared factors in multipliers */
wire al, ah, aa, bl, bh, bb; /* for shared factors */
wire c1, c2, c3; /* for temp var */
assign a = A[7:4];
assign b = A[3:0];
assign sa = a[3:2] ^ a[1:0];
assign sb = b[3:2] ^ b[1:0];
assign al = a[1] ^ a[0];
assign ah = a[3] ^ a[2];
assign aa = sa[1] ^ sa[0];
assign bl = b[1] ^ b[0];
assign bh = b[3] ^ b[2];
assign bb = sb[1] ^ sb[0];
/* optimize this section as shown below
GF_MULS_4 abmul(a, sa, al, ah, aa, b, sb, bl, bh, bb, ab);
GF_SQ_SCL_4 absq( (a ^ b), ab2);
GF_INV_4 dinv( (ab ^ ab2), d);
*/
assign c1 = ~(ah & bh);
assign c2 = ~(sa[0] & sb[0]);
assign c3 = ~(aa & bb);
assign c = { /* note: ~| syntax for NOR won?t compile */
(~(sa[0] | sb[0]) ^ (~(a[3] & b[3]))) ^ c1 ^ c3 ,
(~(sa[1] | sb[1]) ^ (~(a[2] & b[2]))) ^ c1 ^ c2 ,
(~(al | bl) ^ (~(a[1] & b[1]))) ^ c2 ^ c3 ,
(~(a[0] | b[0]) ^ (~(al & bl))) ^ (~(sa[1] & sb[1])) ^ c2 };
GF_INV_4 dinv( c, d);
reg [3:0] a_l1, b_l1, d_l1;
reg [1:0] sa_l1, sb_l1;
reg al_l1,ah_l1, aa_l1, bl_l1, bh_l1, bb_l1;
always @(posedge i_clk) {a_l1, b_l1, d_l1, sa_l1, sb_l1, al_l1,ah_l1, aa_l1, bl_l1, bh_l1, bb_l1} <= {a, b, d, sa, sb, al,ah, aa, bl, bh, bb};
/* end of optimization */
wire [1:0] sd_l1 = d_l1[3:2] ^ d_l1[1:0];
assign dl_l1 = d_l1[1] ^ d_l1[0];
assign dh_l1 = d_l1[3] ^ d_l1[2];
assign dd_l1 = sd_l1[1] ^ sd_l1[0];
wire [3:0] p_l1,q_l1;
GF_MULS_4 pmul(d_l1, sd_l1, dl_l1, dh_l1, dd_l1, b_l1, sb_l1, bl_l1, bh_l1, bb_l1, p_l1);
GF_MULS_4 qmul(d_l1, sd_l1, dl_l1, dh_l1, dd_l1, a_l1, sa_l1, al_l1, ah_l1, aa_l1, q_l1);
assign Q = { p_l1, q_l1 };
endmodule
/* MUX21I is an inverting 2:1 multiplexor */
module MUX21I ( A, B, s, Q );
input A;
input B;
input s;
output Q;
assign Q = ~ ( s ? A : B ); /* mock-up for FPGA implementation */
endmodule
/* select and invert (NOT) byte, using MUX21I */
module SELECT_NOT_8 ( A, B, s, Q );
input [7:0] A;
input [7:0] B;
input s;
output [7:0] Q;
MUX21I m7(A[7],B[7],s,Q[7]);
MUX21I m6(A[6],B[6],s,Q[6]);
MUX21I m5(A[5],B[5],s,Q[5]);
MUX21I m4(A[4],B[4],s,Q[4]);
MUX21I m3(A[3],B[3],s,Q[3]);
MUX21I m2(A[2],B[2],s,Q[2]);
MUX21I m1(A[1],B[1],s,Q[1]);
MUX21I m0(A[0],B[0],s,Q[0]);
endmodule
/* find either Sbox or its inverse in GF(2^8), by Canright Algorithm */
module aes_sbox_canright (
    input wire [7:0] i_dat,
    input wire i_decrypt,
    output wire [7:0] o_dat
    );
wire [7:0] A = i_dat;
wire encrypt = ~i_decrypt; /* 1 for Sbox, 0 for inverse Sbox */
wire [7:0] Q;
assign o_dat = Q;
wire [7:0] B, C, D, X, Y, Z;
wire R1, R2, R3, R4, R5, R6, R7, R8, R9;
wire T1, T2, T3, T4, T5, T6, T7, T8, T9, T10;
/* change basis from GF(2^8) to GF(2^8)/GF(2^4)/GF(2^2) */
/* combine with bit inverse matrix multiply of Sbox */
assign R1 = A[7] ^ A[5] ;
assign R2 = A[7] ~^ A[4] ;
assign R3 = A[6] ^ A[0] ;
assign R4 = A[5] ~^ R3 ;
assign R5 = A[4] ^ R4 ;
assign R6 = A[3] ^ A[0] ;
assign R7 = A[2] ^ R1 ;
assign R8 = A[1] ^ R3 ;
assign R9 = A[3] ^ R8 ;
assign B[7] = R7 ~^ R8 ;
assign B[6] = R5 ;
assign B[5] = A[1] ^ R4 ;
assign B[4] = R1 ~^ R3 ;
assign B[3] = A[1] ^ R2 ^ R6 ;
assign B[2] = ~ A[0] ;
assign B[1] = R4 ;
assign B[0] = A[2] ~^ R9 ;
assign Y[7] = R2 ;
assign Y[6] = A[4] ^ R8 ;
assign Y[5] = A[6] ^ A[4] ;
assign Y[4] = R9 ;
assign Y[3] = A[6] ~^ R2 ;
assign Y[2] = R7 ;
assign Y[1] = A[4] ^ R6 ;
assign Y[0] = A[1] ^ R5 ;
SELECT_NOT_8 sel_in( B, Y, encrypt, Z );
GF_INV_8 inv( Z, C );
/* change basis back from GF(2^8)/GF(2^4)/GF(2^2) to GF(2^8) */
assign T1 = C[7] ^ C[3] ;
assign T2 = C[6] ^ C[4] ;
assign T3 = C[6] ^ C[0] ;
assign T4 = C[5] ~^ C[3] ;
assign T5 = C[5] ~^ T1 ;
assign T6 = C[5] ~^ C[1] ;
assign T7 = C[4] ~^ T6 ;
assign T8 = C[2] ^ T4 ;
assign T9 = C[1] ^ T2 ;
assign T10 = T3 ^ T5 ;
assign D[7] = T4 ;
assign D[6] = T1 ;
assign D[5] = T3 ;
assign D[4] = T5 ;
assign D[3] = T2 ^ T5 ;
assign D[2] = T3 ^ T8 ;
assign D[1] = T7 ;
assign D[0] = T9 ;
assign X[7] = C[4] ~^ C[1] ;
assign X[6] = C[1] ^ T10 ;
assign X[5] = C[2] ^ T10 ;
assign X[4] = C[6] ~^ C[1] ;
assign X[3] = T8 ^ T9 ;
assign X[2] = C[7] ~^ T7 ;
assign X[1] = T6 ;
assign X[0] = ~ C[2] ;
SELECT_NOT_8 sel_out( D, X, encrypt, Q );
endmodule

module aes_sbox_canright_l1 (
	input wire i_clk,
	input wire i_valid,
    input wire [7:0] i_dat,
    input wire i_decrypt,
    output wire [7:0] o_dat,
	output reg o_valid
    );
wire [7:0] A = i_dat;
wire encrypt = ~i_decrypt; /* 1 for Sbox, 0 for inverse Sbox */
wire [7:0] Q;
assign o_dat = Q;
wire [7:0] B, C, D, X, Y, Z;
wire R1, R2, R3, R4, R5, R6, R7, R8, R9;
wire T1, T2, T3, T4, T5, T6, T7, T8, T9, T10;
/* change basis from GF(2^8) to GF(2^8)/GF(2^4)/GF(2^2) */
/* combine with bit inverse matrix multiply of Sbox */
assign R1 = A[7] ^ A[5] ;
assign R2 = A[7] ~^ A[4] ;
assign R3 = A[6] ^ A[0] ;
assign R4 = A[5] ~^ R3 ;
assign R5 = A[4] ^ R4 ;
assign R6 = A[3] ^ A[0] ;
assign R7 = A[2] ^ R1 ;
assign R8 = A[1] ^ R3 ;
assign R9 = A[3] ^ R8 ;
assign B[7] = R7 ~^ R8 ;
assign B[6] = R5 ;
assign B[5] = A[1] ^ R4 ;
assign B[4] = R1 ~^ R3 ;
assign B[3] = A[1] ^ R2 ^ R6 ;
assign B[2] = ~ A[0] ;
assign B[1] = R4 ;
assign B[0] = A[2] ~^ R9 ;
assign Y[7] = R2 ;
assign Y[6] = A[4] ^ R8 ;
assign Y[5] = A[6] ^ A[4] ;
assign Y[4] = R9 ;
assign Y[3] = A[6] ~^ R2 ;
assign Y[2] = R7 ;
assign Y[1] = A[4] ^ R6 ;
assign Y[0] = A[1] ^ R5 ;
SELECT_NOT_8 sel_in( B, Y, encrypt, Z );
always @(posedge i_clk) o_valid <= i_valid;
reg encrypt_l1;
always @(posedge i_clk) encrypt_l1 <= encrypt;
//reg [7:0] Z_l1;
//always @(posedge i_clk) Z_l1 <= Z;
//GF_INV_8 inv( Z_l1, C );
GF_INV_8_l1 inv( i_clk, Z, C );
/* change basis back from GF(2^8)/GF(2^4)/GF(2^2) to GF(2^8) */
assign T1 = C[7] ^ C[3] ;
assign T2 = C[6] ^ C[4] ;
assign T3 = C[6] ^ C[0] ;
assign T4 = C[5] ~^ C[3] ;
assign T5 = C[5] ~^ T1 ;
assign T6 = C[5] ~^ C[1] ;
assign T7 = C[4] ~^ T6 ;
assign T8 = C[2] ^ T4 ;
assign T9 = C[1] ^ T2 ;
assign T10 = T3 ^ T5 ;
assign D[7] = T4 ;
assign D[6] = T1 ;
assign D[5] = T3 ;
assign D[4] = T5 ;
assign D[3] = T2 ^ T5 ;
assign D[2] = T3 ^ T8 ;
assign D[1] = T7 ;
assign D[0] = T9 ;
assign X[7] = C[4] ~^ C[1] ;
assign X[6] = C[1] ^ T10 ;
assign X[5] = C[2] ^ T10 ;
assign X[4] = C[6] ~^ C[1] ;
assign X[3] = T8 ^ T9 ;
assign X[2] = C[7] ~^ T7 ;
assign X[1] = T6 ;
assign X[0] = ~ C[2] ;
SELECT_NOT_8 sel_out( D, X, encrypt_l1, Q );
endmodule

module aes_sbox_lut(
input	wire [7:0]	i_dat,
output	reg [7:0]	o_dat
);
always @(i_dat)
	case(i_dat)		// synopsys full_case parallel_case
	   8'h00: o_dat=8'h63;
	   8'h01: o_dat=8'h7c;
	   8'h02: o_dat=8'h77;
	   8'h03: o_dat=8'h7b;
	   8'h04: o_dat=8'hf2;
	   8'h05: o_dat=8'h6b;
	   8'h06: o_dat=8'h6f;
	   8'h07: o_dat=8'hc5;
	   8'h08: o_dat=8'h30;
	   8'h09: o_dat=8'h01;
	   8'h0a: o_dat=8'h67;
	   8'h0b: o_dat=8'h2b;
	   8'h0c: o_dat=8'hfe;
	   8'h0d: o_dat=8'hd7;
	   8'h0e: o_dat=8'hab;
	   8'h0f: o_dat=8'h76;
	   8'h10: o_dat=8'hca;
	   8'h11: o_dat=8'h82;
	   8'h12: o_dat=8'hc9;
	   8'h13: o_dat=8'h7d;
	   8'h14: o_dat=8'hfa;
	   8'h15: o_dat=8'h59;
	   8'h16: o_dat=8'h47;
	   8'h17: o_dat=8'hf0;
	   8'h18: o_dat=8'had;
	   8'h19: o_dat=8'hd4;
	   8'h1a: o_dat=8'ha2;
	   8'h1b: o_dat=8'haf;
	   8'h1c: o_dat=8'h9c;
	   8'h1d: o_dat=8'ha4;
	   8'h1e: o_dat=8'h72;
	   8'h1f: o_dat=8'hc0;
	   8'h20: o_dat=8'hb7;
	   8'h21: o_dat=8'hfd;
	   8'h22: o_dat=8'h93;
	   8'h23: o_dat=8'h26;
	   8'h24: o_dat=8'h36;
	   8'h25: o_dat=8'h3f;
	   8'h26: o_dat=8'hf7;
	   8'h27: o_dat=8'hcc;
	   8'h28: o_dat=8'h34;
	   8'h29: o_dat=8'ha5;
	   8'h2a: o_dat=8'he5;
	   8'h2b: o_dat=8'hf1;
	   8'h2c: o_dat=8'h71;
	   8'h2d: o_dat=8'hd8;
	   8'h2e: o_dat=8'h31;
	   8'h2f: o_dat=8'h15;
	   8'h30: o_dat=8'h04;
	   8'h31: o_dat=8'hc7;
	   8'h32: o_dat=8'h23;
	   8'h33: o_dat=8'hc3;
	   8'h34: o_dat=8'h18;
	   8'h35: o_dat=8'h96;
	   8'h36: o_dat=8'h05;
	   8'h37: o_dat=8'h9a;
	   8'h38: o_dat=8'h07;
	   8'h39: o_dat=8'h12;
	   8'h3a: o_dat=8'h80;
	   8'h3b: o_dat=8'he2;
	   8'h3c: o_dat=8'heb;
	   8'h3d: o_dat=8'h27;
	   8'h3e: o_dat=8'hb2;
	   8'h3f: o_dat=8'h75;
	   8'h40: o_dat=8'h09;
	   8'h41: o_dat=8'h83;
	   8'h42: o_dat=8'h2c;
	   8'h43: o_dat=8'h1a;
	   8'h44: o_dat=8'h1b;
	   8'h45: o_dat=8'h6e;
	   8'h46: o_dat=8'h5a;
	   8'h47: o_dat=8'ha0;
	   8'h48: o_dat=8'h52;
	   8'h49: o_dat=8'h3b;
	   8'h4a: o_dat=8'hd6;
	   8'h4b: o_dat=8'hb3;
	   8'h4c: o_dat=8'h29;
	   8'h4d: o_dat=8'he3;
	   8'h4e: o_dat=8'h2f;
	   8'h4f: o_dat=8'h84;
	   8'h50: o_dat=8'h53;
	   8'h51: o_dat=8'hd1;
	   8'h52: o_dat=8'h00;
	   8'h53: o_dat=8'hed;
	   8'h54: o_dat=8'h20;
	   8'h55: o_dat=8'hfc;
	   8'h56: o_dat=8'hb1;
	   8'h57: o_dat=8'h5b;
	   8'h58: o_dat=8'h6a;
	   8'h59: o_dat=8'hcb;
	   8'h5a: o_dat=8'hbe;
	   8'h5b: o_dat=8'h39;
	   8'h5c: o_dat=8'h4a;
	   8'h5d: o_dat=8'h4c;
	   8'h5e: o_dat=8'h58;
	   8'h5f: o_dat=8'hcf;
	   8'h60: o_dat=8'hd0;
	   8'h61: o_dat=8'hef;
	   8'h62: o_dat=8'haa;
	   8'h63: o_dat=8'hfb;
	   8'h64: o_dat=8'h43;
	   8'h65: o_dat=8'h4d;
	   8'h66: o_dat=8'h33;
	   8'h67: o_dat=8'h85;
	   8'h68: o_dat=8'h45;
	   8'h69: o_dat=8'hf9;
	   8'h6a: o_dat=8'h02;
	   8'h6b: o_dat=8'h7f;
	   8'h6c: o_dat=8'h50;
	   8'h6d: o_dat=8'h3c;
	   8'h6e: o_dat=8'h9f;
	   8'h6f: o_dat=8'ha8;
	   8'h70: o_dat=8'h51;
	   8'h71: o_dat=8'ha3;
	   8'h72: o_dat=8'h40;
	   8'h73: o_dat=8'h8f;
	   8'h74: o_dat=8'h92;
	   8'h75: o_dat=8'h9d;
	   8'h76: o_dat=8'h38;
	   8'h77: o_dat=8'hf5;
	   8'h78: o_dat=8'hbc;
	   8'h79: o_dat=8'hb6;
	   8'h7a: o_dat=8'hda;
	   8'h7b: o_dat=8'h21;
	   8'h7c: o_dat=8'h10;
	   8'h7d: o_dat=8'hff;
	   8'h7e: o_dat=8'hf3;
	   8'h7f: o_dat=8'hd2;
	   8'h80: o_dat=8'hcd;
	   8'h81: o_dat=8'h0c;
	   8'h82: o_dat=8'h13;
	   8'h83: o_dat=8'hec;
	   8'h84: o_dat=8'h5f;
	   8'h85: o_dat=8'h97;
	   8'h86: o_dat=8'h44;
	   8'h87: o_dat=8'h17;
	   8'h88: o_dat=8'hc4;
	   8'h89: o_dat=8'ha7;
	   8'h8a: o_dat=8'h7e;
	   8'h8b: o_dat=8'h3d;
	   8'h8c: o_dat=8'h64;
	   8'h8d: o_dat=8'h5d;
	   8'h8e: o_dat=8'h19;
	   8'h8f: o_dat=8'h73;
	   8'h90: o_dat=8'h60;
	   8'h91: o_dat=8'h81;
	   8'h92: o_dat=8'h4f;
	   8'h93: o_dat=8'hdc;
	   8'h94: o_dat=8'h22;
	   8'h95: o_dat=8'h2a;
	   8'h96: o_dat=8'h90;
	   8'h97: o_dat=8'h88;
	   8'h98: o_dat=8'h46;
	   8'h99: o_dat=8'hee;
	   8'h9a: o_dat=8'hb8;
	   8'h9b: o_dat=8'h14;
	   8'h9c: o_dat=8'hde;
	   8'h9d: o_dat=8'h5e;
	   8'h9e: o_dat=8'h0b;
	   8'h9f: o_dat=8'hdb;
	   8'ha0: o_dat=8'he0;
	   8'ha1: o_dat=8'h32;
	   8'ha2: o_dat=8'h3a;
	   8'ha3: o_dat=8'h0a;
	   8'ha4: o_dat=8'h49;
	   8'ha5: o_dat=8'h06;
	   8'ha6: o_dat=8'h24;
	   8'ha7: o_dat=8'h5c;
	   8'ha8: o_dat=8'hc2;
	   8'ha9: o_dat=8'hd3;
	   8'haa: o_dat=8'hac;
	   8'hab: o_dat=8'h62;
	   8'hac: o_dat=8'h91;
	   8'had: o_dat=8'h95;
	   8'hae: o_dat=8'he4;
	   8'haf: o_dat=8'h79;
	   8'hb0: o_dat=8'he7;
	   8'hb1: o_dat=8'hc8;
	   8'hb2: o_dat=8'h37;
	   8'hb3: o_dat=8'h6d;
	   8'hb4: o_dat=8'h8d;
	   8'hb5: o_dat=8'hd5;
	   8'hb6: o_dat=8'h4e;
	   8'hb7: o_dat=8'ha9;
	   8'hb8: o_dat=8'h6c;
	   8'hb9: o_dat=8'h56;
	   8'hba: o_dat=8'hf4;
	   8'hbb: o_dat=8'hea;
	   8'hbc: o_dat=8'h65;
	   8'hbd: o_dat=8'h7a;
	   8'hbe: o_dat=8'hae;
	   8'hbf: o_dat=8'h08;
	   8'hc0: o_dat=8'hba;
	   8'hc1: o_dat=8'h78;
	   8'hc2: o_dat=8'h25;
	   8'hc3: o_dat=8'h2e;
	   8'hc4: o_dat=8'h1c;
	   8'hc5: o_dat=8'ha6;
	   8'hc6: o_dat=8'hb4;
	   8'hc7: o_dat=8'hc6;
	   8'hc8: o_dat=8'he8;
	   8'hc9: o_dat=8'hdd;
	   8'hca: o_dat=8'h74;
	   8'hcb: o_dat=8'h1f;
	   8'hcc: o_dat=8'h4b;
	   8'hcd: o_dat=8'hbd;
	   8'hce: o_dat=8'h8b;
	   8'hcf: o_dat=8'h8a;
	   8'hd0: o_dat=8'h70;
	   8'hd1: o_dat=8'h3e;
	   8'hd2: o_dat=8'hb5;
	   8'hd3: o_dat=8'h66;
	   8'hd4: o_dat=8'h48;
	   8'hd5: o_dat=8'h03;
	   8'hd6: o_dat=8'hf6;
	   8'hd7: o_dat=8'h0e;
	   8'hd8: o_dat=8'h61;
	   8'hd9: o_dat=8'h35;
	   8'hda: o_dat=8'h57;
	   8'hdb: o_dat=8'hb9;
	   8'hdc: o_dat=8'h86;
	   8'hdd: o_dat=8'hc1;
	   8'hde: o_dat=8'h1d;
	   8'hdf: o_dat=8'h9e;
	   8'he0: o_dat=8'he1;
	   8'he1: o_dat=8'hf8;
	   8'he2: o_dat=8'h98;
	   8'he3: o_dat=8'h11;
	   8'he4: o_dat=8'h69;
	   8'he5: o_dat=8'hd9;
	   8'he6: o_dat=8'h8e;
	   8'he7: o_dat=8'h94;
	   8'he8: o_dat=8'h9b;
	   8'he9: o_dat=8'h1e;
	   8'hea: o_dat=8'h87;
	   8'heb: o_dat=8'he9;
	   8'hec: o_dat=8'hce;
	   8'hed: o_dat=8'h55;
	   8'hee: o_dat=8'h28;
	   8'hef: o_dat=8'hdf;
	   8'hf0: o_dat=8'h8c;
	   8'hf1: o_dat=8'ha1;
	   8'hf2: o_dat=8'h89;
	   8'hf3: o_dat=8'h0d;
	   8'hf4: o_dat=8'hbf;
	   8'hf5: o_dat=8'he6;
	   8'hf6: o_dat=8'h42;
	   8'hf7: o_dat=8'h68;
	   8'hf8: o_dat=8'h41;
	   8'hf9: o_dat=8'h99;
	   8'hfa: o_dat=8'h2d;
	   8'hfb: o_dat=8'h0f;
	   8'hfc: o_dat=8'hb0;
	   8'hfd: o_dat=8'h54;
	   8'hfe: o_dat=8'hbb;
	   8'hff: o_dat=8'h16;
	endcase
endmodule
module aes_sbox_lut_l1 (
	input wire i_clk,
	input wire i_valid,
    input wire [7:0] i_dat,
    output reg [7:0] o_dat,
	output reg o_valid
    );
wire [7:0] sbox_out;
aes_sbox_lut u_aes_sbox_lut(.i_dat(i_dat), .o_dat(sbox_out));
always @(posedge i_clk) begin
	o_dat <= sbox_out;
	o_valid <= i_valid;
end	
endmodule
`default_nettype wire
