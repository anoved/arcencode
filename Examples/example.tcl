source ../arcencode.tcl
package require gpx

proc SaveToFile {filename contents} {
	set f [open $filename w]
	puts $f $contents
	close $f
}

set data [::gpx::GetTrackPoints [::gpx::Create path.gpx] 1]

# convert {{x y m} ...} trackpoint list to {x y ...} coordinate list
foreach trackpoint $data {lappend coordinates {*}[lrange $trackpoint 0 1]}
#SaveToFile coordinates.txt $coordinates

set encoded [arcencode::arcencode $coordinates]
#SaveToFile encoded.txt $encoded

set decoded [arcencode::arcdecode $encoded]
#SaveToFile decoded.txt $decoded
