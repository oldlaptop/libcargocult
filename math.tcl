namespace eval cargocult {

# From RS on the Tcl wiki (with whitespace altered to fit and some of my
# comments):  https://wiki.tcl-lang.org/page/Regular+polygons
proc rp {x0 y0 x1 y1 {n 0}} {
	set xm [expr {($x0 + $x1) / 2.}]
	set ym [expr {($y0 + $y1) / 2.}]
	set rx [expr {$xm - $x0}]
	set ry [expr {$ym - $y0}]
	if {$n == 0} {
		set n [expr {round(($rx + $ry) * 0.5)}]
	}
	# PJP: Pi div N
	set step [expr {atan(1) * 8 / $n}]
	set res ""
	# PJP: 3*Pi div 2
	set th [expr {atan(1) * 6}] ;#top
	for {set i 0} {$i < $n} {incr i} {
		lappend res \
			[expr {$xm + $rx * cos($th)}] \
			[expr {$ym + $ry * sin($th)}]
		set th [expr {$th + $step}]
	}
	set res
}

} ;# namespace eval cargocult
