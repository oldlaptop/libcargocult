# Snit megawidgets of various kinds.

package require Tcl 8.5 9 ;# {*}
package require Tk 8.5 9  ;# ttk

package require snit 2

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

# Light wrapper around ttk::notebook adding a close button to its tabs.
# Inspiration, and style layout definition, from Georgios Petasis on the wiki
# (heading "Adding an icon to notebook tabs (i.e., close icon)"):
#
# https://wiki.tcl-lang.org/page/ttk%3A%3Anotebook
snit::widgetadaptor cnotebook {
	delegate option * to hull
	delegate method * to hull

	typevariable X

	typeconstructor {
		# It's a 16x16px black X with 8px of padding on the left.
		# (see x.sng)
		set X [image create photo -data \
{iVBORw0KGgoAAAANSUhEUgAAABgAAAAQCAYAAAAMJL+VAAABg2lDQ1BJQ0MgcHJvZmlsZQAAKJF9
kT1Iw0AcxV9TpSIVh3YQcchQnSxIFXXUKhShQqgVWnUwufQLmhiSFBdHwbXg4Mdi1cHFWVcHV0EQ
/ABxdHJSdJES/5cUWsR4cNyPd/ced+8AoVFlmtU1Bmi6bWZSSTGXXxFDrwghAiCBKZlZxqwkpeE7
vu4R4OtdnGf5n/tz9KkFiwEBkXiGGaZNvE48uWkbnPeJo6wsq8TnxKMmXZD4keuKx2+cSy4LPDNq
ZjNzxFFisdTBSgezsqkRTxDHVE2nfCHnscp5i7NWrbHWPfkLwwV9eYnrNIeQwgIWIUGEghoqqMJG
nFadFAsZ2k/6+Addv0QuhVwVMHLMYwMaZNcP/ge/u7WK4wkvKZwEul8c52MYCO0CzbrjfB87TvME
CD4DV3rbv9EApj9Jr7e12BHQvw1cXLc1ZQ+43AEGngzZlF0pSFMoFoH3M/qmPBC5BXpXvd5a+zh9
ALLUVfoGODgERkqUvebz7p7O3v490+rvB7YycsKUE6wiAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBI
WXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH5gcTADQD3mbUEwAAABl0RVh0Q29tbWVudABDcmVhdGVk
IHdpdGggR0lNUFeBDhcAAABlSURBVDiNzZPbEgAQCETl//+ZV6bblprRE9PWEYuGH+tYE6C/aiZY
IMEgTRTgQVguPLJRK2pQgAdRcxGA1kgKYotCCKmbAgjrl3FRKL67otZHbrVp60dDmqvajIusQz3b
FJn40mzYYBUUts2hfAAAAABJRU5ErkJggg==}]

		# Arrange our styles. We'd really rather not change all the
		# other ttk::notebooks an application may or may not have.

		# Clone TNotebook...
		ttk::style layout CNotebook [ttk::style layout TNotebook]
		ttk::style map CNotebook {*}[ttk::style map TNotebook]
		ttk::style map CNotebook.Tab {*}[ttk::style map TNotebook.Tab]

		# ...and separate the image and label, so we can independently
		# react to clicks on the image.
		ttk::style layout CNotebook.Tab {
			Notebook.tab -children {
				Notebook.padding -side top -children {
					Notebook.focus -side top -children {
						Notebook.text -side left
						Notebook.image -side right
					}
				}
			}
		}
	}

	constructor {args} {
		installhull using ttk::notebook -style CNotebook
		$self configurelist $args

		bind $win <ButtonPress-1>  +[mymethod click %x %y]
	}

	method add {args} {
		$hull add [lindex $args 0] -image $X {*}[lrange $args 1 end]
	}

	method click {x y} {
		if {[$self identify element $x $y] eq {image}} {
			destroy [lindex [$self tabs] [$self identify tab $x $y]]
		}
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

# ttk::treeview with matching vertical ttk::scrollbar.
snit::widget scrolltree {
	hulltype ttk::frame

	component tree
	component vscroll

	delegate method set to vscroll

	delegate method * to tree
	delegate option * to tree

	constructor {args} {
		install tree using ttk::treeview $win.treeview \
			-yscrollcommand [mymethod set]
		install vscroll using ttk::scrollbar $win.vscroll \
			-command [mymethod yview]

		grid $tree $vscroll -sticky nsew
		grid rowconfigure $win 0 -weight 1
		grid columnconfigure $win 0 -weight 1

		$self configurelist $args
	}
}

} ;# namespace eval cargocult
