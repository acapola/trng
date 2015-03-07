create_clock -period 83.33 -name CLK [get_ports CLK]
create_clock -period 10.0 -name  CLKOP [get_nets CLKOP]         
if {0} {
	set_false_path -through [get_nets f_FP]
	set_false_path -through [get_nets r_FP]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage0/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage1/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage1/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage2/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage2/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage3/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage3/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage4/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage4/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage5/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage5/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage6/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage6/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage0/*]                                              
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage2/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage1/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage3/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage2/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage4/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage3/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage5/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage4/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage6/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage5/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage0/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage6/*]
	set_false_path -from [get_cells \u_trng_top/trng/u0_rnd_src/stage1/LUT5_inst/i4] -to [get_cells \u_trng_top/trng/u0_rnd_src/stage0/*]
	set_false_path -through [get_nets u_trng_top/trng/rnd_src_dat[0]]
	set_false_path -through [get_nets \u_trng_top/trng/u0_rnd_src/stage1/LUT5_inst/O0]
}
#does not seems to work
for {set i 0} {$i<4} {incr i} {
	for {set j 0} {$j<7} {incr j} {
		set_false_path -through [get_nets \u_trng_top/trng/u${i}_rnd_src/stage${j}/LUT5_inst/O0]
	}
}