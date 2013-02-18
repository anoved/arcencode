#!/usr/bin/tclsh

# quick and dirty implementation of MapQuest coordinate compression:
#http://open.mapquestapi.com/common/encodedecode.html

# (default precision of 5 matches Google Maps' Encoded Polyline algorthim:
#https://developers.google.com/maps/documentation/utilities/polylinealgorithm

proc decompress {encoded {precision 5}} {
	set p [expr {pow(10, -$precision)}]
	set len [string length $encoded]
	set index 0
	set lat 0
	set lng 0
	set points {}
	
	while {$index < $len} {
		
		set shift 0
		set result 0
		
		while {1} {
			set b [expr {[scan [string index $encoded $index] %c] - 63}]
			incr index
			set result [expr {$result | (($b & 0x1f) << $shift)}]
			set shift [expr {$shift + 5}]
			if {$b < 0x20} {
				break
			}
		}
		
		set dlat [expr {(($result & 1) ? ~($result >> 1) : ($result >> 1))}]
		set lat [expr {$lat + $dlat}]
		
		set shift 0
		set result 0
		
		while {1} {
			set b [expr {[scan [string index $encoded $index] %c] - 63}]
			incr index
			set result [expr {$result | (($b & 0x1f) << $shift)}]
			set shift [expr {$shift + 5}]
			if {$b < 0x20} {
				break
			}
		}
		
		set dlng [expr {(($result & 1) ? ~($result >> 1) : ($result >> 1))}]
		set lng [expr {$lng + $dlng}]
		
		
		
		lappend points [format %.*f $precision [expr {$lat * $p}]]
		lappend points [format %.*f $precision [expr {$lng * $p}]]
	}
	
	return $points
}

proc encodeNumber {num} {
	set num [expr {$num << 1}]
	if {$num < 0} {
		set num [expr {~$num}]
	}
	set encoded {}
	while {$num > 0x20} {
		append encoded [format %c [expr {(0x20 | ($num & 0x1f)) + 63}]]
		set num [expr {$num >> 5}]
	}
	append encoded [format %c [expr {$num + 63}]]
}

proc compress {points {precision 5}} {
	set oldLat 0
	set oldLng 0
	set precision [expr {pow(10, $precision)}]
	set encoded {}
	
	foreach {lat lng} $points {
		
		# Round to N decimal places
		set lat [expr {round($lat * $precision)}]
		set lng [expr {round($lng * $precision)}]
		
		# Encode the differences between the points
		append encoded [encodeNumber [expr {$lat - $oldLat}]]
		append encoded [encodeNumber [expr {$lng - $oldLng}]]
		
		set oldLat $lat
		set oldLng $lng
	}
	
	return $encoded
}


set p {
45.967 -83.928700032549
55 -83.928420000
35 -83.97948699748273
25.000000 -83.000000
15.00000000000 -83.9279400000
0.9600 -83.9275623435
35.90 -0.90
35.900 -83.00
35.000 -83.000
35.90000 -83.0000
35.00000 -83.00000
35.000004190 -83.00000123490
}

set c [compress $p 5]
puts $c
set d [decompress $c 5]
puts $d
puts "===="
puts [decompress "_p~iF~ps|U_ulLnnqC_mqNvxq`@"]

