# Snit megawidgets of various kinds.

package require Tcl 8.5 ;# {*}
package require Tk 8.5 ;# ttk

package require snit 2.2

package require cargocult
package require cargocult::tk
package provide cargocult::widgets 0.1

namespace eval cargocult {

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

# Generic widget that builds up a single-column list of some other kind of
# widget, which should ideally have some self-destruct mechanism. Generates
# <<NewDynrow>> when a new row is added to the list, and <<RmDynrow>> when one
# of its rows is destroyed.
snit::widget dynrows {
	hulltype ttk::labelframe
	delegate option * to hull
	delegate method * to hull

	option -newrow -default {ttk::label}

	option -rowopts \
		-default {-text "You should change -newrow and -rowopts." } \
		-configuremethod Set_rowopts
	method Set_rowopts {opt val} {
		foreach row [$self rows] {
			$row configure {*}$val
		}
		set options($opt) $val
	}

	option -noun -default thing

	component cv
	component scroll
	component rowsframe

	variable scrolltag

	constructor {args} {
		set scrolltag [gensym scrolltag]

		install cv using canvas $win.cv \
			-yscrollcommand [list $win.scroll set]
		install rowsframe using ttk::frame $cv.aggrows
		install scroll using ttk::scrollbar $win.scroll \
			-orient vertical -command [list $win.cv yview]

		$cv create window [tk scaling] [tk scaling] \
			-anchor nw -window $rowsframe -tags rowsframe

		bind $cv <Configure> [mymethod Resize canvas %w %h]
		bind $rowsframe <Configure> [mymethod Resize frame %w %h]

		$self configurelist $args

		ttk::button $win.add -text "Add [$self cget -noun]" -style Toolbutton -command [mymethod add_row]

		grid $cv      $scroll -sticky nsew
		grid $win.add -       -sticky se
		grid rowconfigure $win 0 -weight 1
		grid columnconfigure $win 0 -weight 1
		grid columnconfigure $rowsframe 0 -weight 1

		foreach window [concat $win [winfo children $win] $rowsframe [winfo children $rowsframe]] {
			$self Set_scrolltarget $window
		}

		install_scrollbinds $scrolltag [list $cv yview scroll :dir units]
	}

	# Add a new row to the list. Any arguments are taken as ad-hoc options
	# for this particular row.
	method add_row {args} {
		grid [set newrow [{*}[$self cget -newrow] $rowsframe.row[gensym dynrow] {*}[$self cget -rowopts] {*}$args]] \
			-sticky ew -padx [tk scaling] -pady [tk scaling]
		# Jump to bottom
		after idle [list $cv yview moveto 1]
		$self Set_scrolltarget $newrow

		event generate $win <<NewDynrow>>
		bind $newrow <Destroy> [list event generate $win <<RmDynrow>>]
	}

	method rows {} {
		winfo children $rowsframe
	}

	method Resize {window newwidth newheight} {
		if {$window eq "canvas"} {
			$cv itemconfigure rowsframe -width [- $newwidth 4]
		} else {
			$cv configure -scrollregion [list 0 0 $newwidth $newheight]
		}
	}

	method Set_scrolltarget {window} {
		bindtags $window [linsert [bindtags $window] 1 $scrolltag]
		catch {$window Add_scrolltags $scrolltag} err
	}
}

# Example row-widget for dynrows, used to specify a single string key/value pair
snit::widget kvpair {
	hulltype ttk::frame

	component label
	component keyen
	component valen

	delegate method * to hull
	delegate option * to hull

	delegate option -text to label
	delegate option -key_validate to keyen as -validate
	delegate option -value_validate to valen as -validate
	delegate option -key_validatecommand to keyen as -validatecommand
	delegate option -value_validatecommand to valen as -validatecommand
	delegate option -key_invalidcommand to keyen as -invalidcommand
	delegate option -value_invalidcommand to valen as -invalidcommand

	option -key
	option -value

	constructor {args} {
		install label using ttk::label $win.label

		install keyen using ttk::entry $win.keyen -textvariable [
			myvar options(-key)
		]
		install valen using ttk::entry $win.valen -textvariable [
			myvar options(-value)
		]

		ttk::button $win.destroy -text X -width 0 -command [list destroy $win]

		grid $label $win.keyen $win.valen $win.destroy -sticky nsew
		grid rowconfigure $win 0 -weight 1
		grid columnconfigure $win {1 2} -weight 1
		pad_grid_widgets [winfo children $win]

		$self configurelist $args
	}
}

proc test_dynrows {{parent {}}} {
	if {$parent eq {}} {
		set parent [toplevel .[gensym test_dynrows]]
	}
	grid [set ret [dynrows $parent.dynrows -newrow kvpair -rowopts {}]] -sticky nsew
	grid rowconfigure $parent 0 -weight 1
	grid columnconfigure $parent 0 -weight 1

	return $ret
}

} ;# namespace eval cargocult
