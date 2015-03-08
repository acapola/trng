proc removeBits { inFileName filter {maxLength 0} } {
	set fin [open $inFileName]
	fconfigure $fin -translation binary
	set outFileName "${inFileName}_packed.dat"
	set fout [open $outFileName [list WRONLY CREAT TRUNC BINARY]]
	set cnt 0
	#we count in bits rather than bytes
	set maxLength [expr $maxLength*8]
	set bOut 0
	set bOutIndex 0
	while { 1 } {
		set bBin [read $fin 1]
		if {$bBin==""} {break}
		binary scan $bBin c b
		#puts "in: '$bBin' -> 0x[format %02X $b]"
		for {set i 0} {$i<8} {incr i} {
			set accept [$filter $cnt]
			incr cnt
			if {$accept} {
				set bOut [expr $bOut | ((($b>>$i) & 1)<<$bOutIndex)]
				#puts "0x[format %02X $bOut]"
				incr bOutIndex
				if {$bOutIndex==8} {
					puts -nonewline $fout [binary format c1 $bOut]
					set bOutIndex 0
					set bOut 0
				}
			}
		}
		if {$cnt==$maxLength} {break}
	}
	close $fout
	close $fin
}
proc orthogonalStreams_old { inFileName blockLength } {
	set fin [open $inFileName]
	fconfigure $fin -translation binary
	set finLength [file size $inFileName]
	set nBlocks [expr $finLength / $blockLength]
	set fouts [list]
	for {set i 0} {$i<$nBlocks} {incr i} {
		set outFileName "${inFileName}_ortho_[format "%02u" $i].dat"
		set fout [open $outFileName [list WRONLY CREAT TRUNC BINARY]]
		fconfigure $fout -translation binary
		lappend fouts $fout
	}
	rawToText $fin $fout $blockLength
	close $fout
	skipBlock $fin [expr (1024-16)*1024]
	
	close $fin
	foreach fout $fouts {
		close $fout
	}
}
proc orthogonalStreams { inFileName blockLength } {
	set fin [open $inFileName]
	fconfigure $fin -translation binary
	set finLength [file size $inFileName]
	set nBlocks [expr $finLength / $blockLength]
	set outFileName "${inFileName}_ortho_${blockLength}.dat"
	set fout [open $outFileName [list WRONLY CREAT TRUNC BINARY]]
	fconfigure $fout -translation binary
	for {set i 0} {$i<$blockLength} {incr i} {
		seek $fin $i start
		for {set block 0} {$block < $nBlocks} {incr block} {
			set bBin [read $fin 1]
			binary scan $bBin c b
			#puts $b
			puts -nonewline $fout [binary format c1 $b]
			seek $fin [expr $blockLength-1] current
		}
	}
	close $fin
	close $fout
}

#94949494
#10010100 10010100 10010100 10010100 
#1001010  1001010  1001010  1001010
#01001010 10100101 01010010
#4AA552

proc filterByteLsb { bitIndex } {
	if {0==($bitIndex%8)} {return 0}
	return 1
}

set inFileName "icestick.dat"
if {0} {
	#for raw stream analysis
	set inFileName "20111112_4x7s96MHz_raw16k_periodic_reset64.dat"
	removeBits $inFileName filterByteLsb
	append inFileName _packed.dat
}
orthogonalStreams $inFileName [expr 16*1024]