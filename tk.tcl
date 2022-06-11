# Tk and otherwise GUI-related cargo.

package require Tcl 8.5 ;# {*}
package require Tk 8.5 ;# ttk

package require snit 2.2

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

# Megawidget for constructing {-option value} style lists, such as those most
# Tk widgets (and Tcl object-oids in general) require for setting their options.
# The generated interface will have one row for each option, each containing a
# checkbutton and an entry (or other similar widget, see the -rows option); when
# the checkbutton is checked, the entry widget will be enabled and the user can
# (presumably) specify a value for the option. The option_list method may then
# be used to generate the {-option value} list for use with some actual command.
snit::widget optionlist {
	hulltype ttk::frame

	delegate method * to hull
	delegate option * to hull

	# Should contain six elements for each option, or each row in the UI:
	#
	# option:           name of the option, as passed to the command (but
	#                   without the leading -)
	# text:             text for the checkbutton, i.e. an appropriate user-
	#                   visible label for the option
	# entrywidget:      widget-command used to create the widget with which
	#                   the user is to specify the value; reasonable options
	#                   include but are not necessarily limited to
	#                   ttk::entry and its derivatives (such as
	#                   ttk::spinbox). Must support a -textvariable option.
	# entrywidget_opts: Extra -options to be passed to entrywidget.
	# enabled:          Whether the option is enabled (i.e. the checkbutton
	#                   is checked) initially.
	# default:          Initial value for the option.
	option -rows -default {} -readonly yes

	variable option_values -array {}
	variable set_option -array {}
	variable entries -array {}

	constructor {args} {
		$self configurelist $args

		foreach {
			option text entrywidget entrywidget_opts enabled default
		} [$self cget -rows] {
			set checkbutton [ttk::checkbutton $win.${option}cb -text $text -variable [myvar set_option($option)] -command [mymethod Toggle_state $option]]
			set entries($option) [set entry [$entrywidget $win.${option}en -textvariable [myvar option_values($option)] {*}$entrywidget_opts]]

			set set_option($option) $enabled
			set option_values($option) $default
			$self Toggle_state $option

			grid $checkbutton $entry -sticky new
		}

		grid columnconfigure $win 1 -weight 1
		pad_grid_widgets [winfo children $win]
	}

	# Returns the currently-selected option list. The list will include one
	# {-option value} stanza for every option whose checkbutton is checked.
	method option_list {} {
		set ret [list]
		foreach {opt val} [array get option_values] {
			if {$set_option($opt)} {
				lappend ret -$opt $val
			}
		}
		return $ret
	}

	# Enable or disable the entry widget associated with the option $opt as
	# appropriate.
	method Toggle_state {opt} {
		$entries($opt) state [expr {$set_option($opt) ? {!disabled} : {disabled}}]
	}
}

} ;# namespace eval cargocult
