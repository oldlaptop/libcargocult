# Tk and otherwise GUI-related cargo.
package require Tk ;# May randomly change to Tk 8.5 in the future as needed

package require cargocult
package provide cargocult::tk 0.1

namespace eval cargocult {

# Applies padding to a list of grid-ed widgets, auto-applying [tk scaling]
proc pad_grid_widgets {widgetList {amt 1}} {
	set amt [expr {ceil($amt * [tk scaling])}]
	foreach widget $widgetList {
		grid configure $widget -padx $amt -pady $amt
	}
}

} ;# namespace eval cargocult
