namespace eval cargocult {

# Recursive glob(n); performs a recursive search for paths matching $pattern
# under the directory $root and returns a list of all results. Should behave
# vaguely like [split [exec find $root -name $pattern] \n] or so on Unix. If
# $types is specified, it is passed directly to glob(n) as its -types option.
#
# Originally written as a coroutine that yielded one individual path per
# invocation, but the author has since only had cause to cargo-cult this
# blocking version.
proc rglob {root pattern {types f}} {
	concat [glob -nocomplain -directory $root -types $types $pattern] [
		join [lmap dir [glob -nocomplain -directory $root -types d *] {
			rglob $dir $pattern
		}]
	]
}

} ;# namespace eval cargocult
