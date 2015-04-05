module trng_pll_96MHz(REFERENCECLK,
                      PLLOUTCORE,
                      PLLOUTGLOBAL,
                      RESET);

input wire REFERENCECLK;
input wire RESET;    /* To initialize the simulation properly, the RESET signal (Active Low) must be asserted at the beginning of the simulation */ 
output wire PLLOUTCORE;
output wire PLLOUTGLOBAL;

SB_PLL40_CORE trng_pll_96MHz_inst(.REFERENCECLK(REFERENCECLK),
                                  .PLLOUTCORE(PLLOUTCORE),
                                  .PLLOUTGLOBAL(PLLOUTGLOBAL),
                                  .EXTFEEDBACK(1'b0),
                                  .DYNAMICDELAY(0),
                                  .RESETB(RESET),
                                  .BYPASS(1'b0),
                                  .LATCHINPUTVALUE(0),
                                  .LOCK(),
                                  .SDI(0),
                                  .SDO(),
                                  .SCLK(0));

//\\ Fin=12, Fout=96;
defparam trng_pll_96MHz_inst.DIVR = 4'b0000;
defparam trng_pll_96MHz_inst.DIVF = 7'b0111111;
defparam trng_pll_96MHz_inst.DIVQ = 3'b011;
defparam trng_pll_96MHz_inst.FILTER_RANGE = 3'b001;
defparam trng_pll_96MHz_inst.FEEDBACK_PATH = "SIMPLE";
defparam trng_pll_96MHz_inst.DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED";
defparam trng_pll_96MHz_inst.FDA_FEEDBACK = 4'b0000;
defparam trng_pll_96MHz_inst.DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED";
defparam trng_pll_96MHz_inst.FDA_RELATIVE = 4'b0000;
defparam trng_pll_96MHz_inst.SHIFTREG_DIV_MODE = 2'b00;
defparam trng_pll_96MHz_inst.PLLOUT_SELECT = "GENCLK";
defparam trng_pll_96MHz_inst.ENABLE_ICEGATE = 1'b0;

endmodule
