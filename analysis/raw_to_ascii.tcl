proc byteToBools { byteValue } {
	set out [list]
	for {set i 0} {$i<8} {incr i} {
		lappend out [expr ($byteValue>>$i) & 1]
	}
	return $out
}

proc skipBlock { fin length } {
	set maxSize [expr 1024*1024]
	set nLoops [expr $length / $maxSize]
	for {set i 0} {$i<$nLoops} {incr i} {
		read $fin $maxSize
	}
	set remaining [expr $length - $nLoops * $maxSize]
	read $fin $remaining
	return ""
}

proc rawToText { fin fout {maxLength 0} } {
	fconfigure $fin -translation binary
	set cnt 0
	while { 1 } {
		set bBin [read $fin 1]
		if {$bBin==""} {break}
		set bText ""
		binary scan $bBin b* bText
		puts -nonewline $fout "[string range $bText 1 7] "
		incr cnt
		if {$cnt%4==0} {puts -nonewline $fout "\n"}
		if {$cnt==$maxLength} {break}
	}
}


set inFileName "20141119_4x7s96MHz_1001000_raw16k_periodic_reset64.dat"
#set inFileName "test.dat"

set fin [open $inFileName]
for {set i 0} {$i<64} {incr i} {
	set outFileName "${inFileName}_[format "%02u" $i].txt"
	set fout [open $outFileName [list WRONLY CREAT TRUNC]]
	rawToText $fin $fout [expr 16*1024]
	close $fout
	skipBlock $fin [expr (1024-16)*1024]
}
close $fin
