# Tk and otherwise GUI-related cargo.

package require Tk 8.5 ;# May again randomly change to 8.5 if needed

package require snit 2.2

package require cargocult
package provide cargocult::tk 0.2

namespace eval cargocult {

# Applies padding to a list of grid-ed widgets, auto-applying [tk scaling]
proc pad_grid_widgets {widgetList {amt 1}} {
	set amt [expr {ceil($amt * [tk scaling])}]
	foreach widget $widgetList {
		grid configure $widget -padx $amt -pady $amt
	}
}

# Installs scroll-wheel bindings for the widget $win. scrollcmd is a Tcl command
# to be executed when scroll events fire; before execution, the string ':dir' is
# substituted with either -1 or 1, the former if the scrollwheel was moved up,
# and the latter if it was moved down.
proc install_scrollbinds {win scrollcmd} {
	set scroll_lambda {{c dir} {{*}[string map ":dir $dir" $c]}}
	# Unfortunately mousewheel support is a bit wonky on x11.
	switch [tk windowingsystem] {
		x11 {
			# x11 maps mousewheel events to mouse-"buttons" 4 and 5.
			# Usually.
			bind $win <Button-4> [list apply $scroll_lambda $scrollcmd -1]
			bind $win <Button-5> [list apply $scroll_lambda $scrollcmd 1]
		}
		win32 -
		aqua -
		default {
			# We only care about the sign.
			bind $win <MouseWheel> [string cat [list apply $scroll_lambda $scrollcmd] { [expr {%D > 0 ? -1 : 1}]}]
		}
	}
}

# Wait, modally, for the window $dialog to be destroyed. WARNING: this enters
# the event loop with tkwait and therefore has unbounded side effects, much like
# tk_messageBox and family.
#
# See https://wiki.tcl-lang.org/page/Modal+dialogs
proc modalize {dialog {master ""}} {
	grab $dialog

	if {$master ne ""} {
		wm transient $dialog $master
	}

	wm protocol $dialog WM_DELETE_WINDOW [list apply { {dialog args} {
		grab release $dialog
		destroy $dialog
	}} $dialog]
	raise $dialog
	tkwait window $dialog
}

} ;# namespace eval cargocult
