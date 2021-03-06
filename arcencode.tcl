namespace eval arcencode {
	set version 0.1
	namespace export arcencode arcdecode
}

proc arcencode::arcdecode {encoded {precision 5}} {
	
	# strip whitespace from encoded string
	regsub -all {\s} $encoded {} encoded
	
	set pfactor [expr {pow(10, -$precision)}]
	set len [string length $encoded]
	set index 0
	set a 0
	set b 0
	set points {}
	
	while {$index < $len} {
		
		# read the first coordinate
		
		set shift 0
		set result 0
		while {1} {
			
			# read a character value from the encoded string
			set val [expr {[scan [string index $encoded $index] %c] - 63}]
			incr index
			
			# look at the rightmost 5 bits with & 0b11111; for each successive
			# char, shift it left 5 and | with current result to accumulate num.
			set result [expr {$result | (($val & 0b11111) << $shift)}]
			incr shift 5
			
			# no more chars needed for this val if the high bit is not set
			if {$val < 0b100000} {
				break
			}
		}
		
		# if the result is odd, flip bits after shifting right to restore neg.
		set deltaA [expr {(($result & 1) ? ~($result >> 1) : ($result >> 1))}]
		
		# add delta to last value to get new value
		set a [expr {$a + $deltaA}]
		
		# repeat for the other member of the coordinate pair
		
		set shift 0
		set result 0
		while {1} {
			set val [expr {[scan [string index $encoded $index] %c] - 63}]
			incr index
			set result [expr {$result | (($val & 0b11111) << $shift)}]
			incr shift 5
			if {$val < 0b100000} {
				break
			}
		}
		set deltaB [expr {(($result & 1) ? ~($result >> 1) : ($result >> 1))}]
		set b [expr {$b + $deltaB}]
		
		# convert coordinates back to floating point and append to point list
		lappend points [format %.*f $precision [expr {$a * $pfactor}]]
		lappend points [format %.*f $precision [expr {$b * $pfactor}]]
	}
	
	return $points
}

proc arcencode::arcencode {points {precision 5}} {
	
	set pfactor [expr {pow(10, $precision)}]
	
	set encoded {}
	set lastA 0
	set lastB 0
	
	foreach {a b} $points {
		
		# Convert these coordinates to integers
		set a [expr {round($a * $pfactor)}]
		set b [expr {round($b * $pfactor)}]
		
		# Encode the difference between these coordinates and the old ones.
		append encoded [encodeNumber [expr {$a - $lastA}]]
		append encoded [encodeNumber [expr {$b - $lastB}]]
		
		set lastA $a
		set lastB $b
	}
	
	return $encoded
}

proc arcencode::encodeNumber {num} {
	
	# shift left one bit
	set num [expr {$num << 1}]
	
	# invert bits if negative
	if {$num < 0} {
		set num [expr {~$num}]
	}
	
	# if the value occupies more than 5 bits, encode each 5-bit chunk separately
	set encoded {}
	while {$num >= 0b100000} {
		
		# get the rightmost 5 bits with & 0b11111; indicate that this value
		# is comprised of more chunks to follow by setting the 0b100000 bit
		append encoded [format %c [expr {(0b100000 | ($num & 0b11111)) + 63}]]
		
		# shift value right 5 bits in preparation for encoding the next chunk
		set num [expr {$num >> 5}]
	}
	
	# encode the final 5-bit chunk
	append encoded [format %c [expr {$num + 63}]]
	return $encoded
}

package provide arcencode $arcencode::version
