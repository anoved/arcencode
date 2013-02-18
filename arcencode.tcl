#!/usr/bin/tclsh

namespace eval arcencode {
	set version 0.1
	namespace export arcencode arcdecode
}

proc arcencode::arcdecode {encoded {precision 5}} {
	set pfactor [expr {pow(10, -$precision)}]
	set len [string length $encoded]
	set index 0
	set lat 0
	set lng 0
	set points {}
	
	while {$index < $len} {
		
		# read a latitude coordinate
		set shift 0
		set result 0
		while {1} {
			set b [expr {[scan [string index $encoded $index] %c] - 63}]
			incr index
			set result [expr {$result | (($b & 0b11111) << $shift)}]
			incr shift 5
			if {$b < 0b100000} {
				break
			}
		}
		set dlat [expr {(($result & 1) ? ~($result >> 1) : ($result >> 1))}]
		set lat [expr {$lat + $dlat}]
		
		# read a longitude coordinate
		set shift 0
		set result 0
		while {1} {
			set b [expr {[scan [string index $encoded $index] %c] - 63}]
			incr index
			set result [expr {$result | (($b & 0b11111) << $shift)}]
			incr shift 5
			if {$b < 0b100000} {
				break
			}
		}
		set dlng [expr {(($result & 1) ? ~($result >> 1) : ($result >> 1))}]
		set lng [expr {$lng + $dlng}]
		
		
		lappend points [format %.*f $precision [expr {$lat * $pfactor}]]
		lappend points [format %.*f $precision [expr {$lng * $pfactor}]]
	}
	
	return $points
}

proc arcencode::arcencode {points {precision 5}} {
	
	set pfactor [expr {pow(10, $precision)}]
	
	set encoded {}
	set oldLat 0
	set oldLng 0
	
	foreach {lat lng} $points {
		
		# Convert these coordinates to integers
		set lat [expr {round($lat * $pfactor)}]
		set lng [expr {round($lng * $pfactor)}]
		
		# Encode the difference between these coordinates and the old ones.
		append encoded [encodeNumber [expr {$lat - $oldLat}]]
		append encoded [encodeNumber [expr {$lng - $oldLng}]]
		
		set oldLat $lat
		set oldLng $lng
	}
	
	return $encoded
}

proc arcencode::encodeNumber {num} {
	
	# left shift one bit
	set num [expr {$num << 1}]
	
	# invert bits if negative
	if {$num < 0} {
		set num [expr {~$num}]
	}
	
	
	set encoded {}
	while {$num > 0b100000} {
		append encoded [format %c [expr {(0b100000 | ($num & 0b11111)) + 63}]]
		set num [expr {$num >> 5}]
	}
	
	append encoded [format %c [expr {$num + 63}]]
	return $encoded
}

package provide arcencode $arcencode::version
