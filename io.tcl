# I/O related cargo.

package require Tcl 8.6

namespace eval cargocult {

# "Safe" file-use construct: sets $fdvar to $fd and executes $script, closing
# $fd and, if an error occurs, rethrowing it. The parameter 'as' is ignored as
# syntactic sugar. Example usage:
# with [open /tmp/foo r] as fd {
#       puts [read $fd]
# }
proc with {fd as fdvar script} {
	try {
		uplevel 1 set $fdvar $fd
		uplevel 1 $script
	} on error {err opts} {
		return -options $opts $err
	} finally {
		close $fd
	}
}

# Debugging utility: behaves like puts, but returns the string written.
proc puts_through {args} {
	puts {*}$args
	return [lindex $args end]
}

} ;# namespace eval cargocult
