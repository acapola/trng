module trng_pll_100MHz(REFERENCECLK,
                       PLLOUTCORE,
                       PLLOUTGLOBAL,
                       RESET);

input REFERENCECLK;
input RESET;    /* To initialize the simulation properly, the RESET signal (Active Low) must be asserted at the beginning of the simulation */ 
output PLLOUTCORE;
output PLLOUTGLOBAL;

SB_PLL40_CORE trng_pll_100MHz_inst(.REFERENCECLK(REFERENCECLK),
                                   .PLLOUTCORE(PLLOUTCORE),
                                   .PLLOUTGLOBAL(PLLOUTGLOBAL),
                                   .EXTFEEDBACK(),
                                   .DYNAMICDELAY(),
                                   .RESETB(RESET),
                                   .BYPASS(1'b0),
                                   .LATCHINPUTVALUE(),
                                   .LOCK(),
                                   .SDI(),
                                   .SDO(),
                                   .SCLK());

//\\ Fin=12, Fout=100;
defparam trng_pll_100MHz_inst.DIVR = 4'b0000;
defparam trng_pll_100MHz_inst.DIVF = 7'b1000010;
defparam trng_pll_100MHz_inst.DIVQ = 3'b011;
defparam trng_pll_100MHz_inst.FILTER_RANGE = 3'b001;
defparam trng_pll_100MHz_inst.FEEDBACK_PATH = "SIMPLE";
defparam trng_pll_100MHz_inst.DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED";
defparam trng_pll_100MHz_inst.FDA_FEEDBACK = 4'b0000;
defparam trng_pll_100MHz_inst.DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED";
defparam trng_pll_100MHz_inst.FDA_RELATIVE = 4'b0000;
defparam trng_pll_100MHz_inst.SHIFTREG_DIV_MODE = 2'b00;
defparam trng_pll_100MHz_inst.PLLOUT_SELECT = "GENCLK";
defparam trng_pll_100MHz_inst.ENABLE_ICEGATE = 1'b0;

endmodule
