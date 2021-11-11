# sqlite-related cargo; no hard dependency on sqlite3 itself, but some commands
# require an sqlite database handle as an argument, and none are useful without
# some sql database or other.

namespace eval cargocult {

# Quote a string as a SQL quoted identifier.
proc sql_name {str} {
	return \"[string map [list \" \"\"] $str]\"
}

# Quote a string as an SQL quoted identifier, treating the first dot as the
# separator between the table and column names.
proc sql_column {str} {
	if {[set pivot [string first . $str]] >= 0} {
		return [sql_name [string range $str 0 $pivot-1]].[sql_name [string range $str $pivot+1 end]]
	} else {
		return [sql_name $str]
	}
}

# Quote a string as a SQL value (with sqlite's QUOTE() function)
proc sql_val {db str} {
	return [$db onecolumn {
		SELECT QUOTE(:str)
	}]
}

# Configure the sqlite database $db according to upstream recommendations for
# sane behavior as far as possible: enable foreign keys, clamp down on funky
# dangerous stuff in schemas, and ban double-quoted string literals.
proc make_sane {db {sqlite_version 9001}} {
	$db eval {
		PRAGMA trusted_schema = 0;
		PRAGMA foreign_keys = ON;
	}
	if {[package vsatisfies $sqlite_version 3.30.0-]} {
		$db config defensive 1
		$db config dqs_dml 0;
		$db config dqs_ddl 0;
	} else {
		puts {warning: this version of sqlite doesn't support $db config}
	}
}

} ;# namespace eval cargocult
