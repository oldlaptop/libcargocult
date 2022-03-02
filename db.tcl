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

# Quote a string as a SQL value (with sqlite's QUOTE() function); note that
# SQLite is sensitive to Tcl's internal representations, i.e. this proc violates
# EIAS. Consider [string cat $str] or perhaps [tcl::mathfunc::int $str] and
# friends for maximum consistency in the SQL-level type of the result.
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

# Suppose we have a table table (or in principle a subquery or something) with
# a key-value-style schema of this rough form:
#
# CREATE TABLE foo (
#     record_key INTEGER,
#     field ANY,
#     val ANY,
#
#     UNIQUE (record_key, field)
# )
#
# kv2table is intended to generate a query on this table presenting it with a
# more relational-style schema, with record_key as the (pseudo-)primary key,
# the values of field as column names, and their values for each value of
# record_key as column values.
#
# projection is a list of (quoted as necessary) SQL expressions to include in
# the query's projection alongside the key/value columns; it should include at
# least record_key, since a DISTINCT query is generated. As will become a
# theme, this is substituted directly into the query and may be an
# arbitrary expression, or a Bobby Tables shenanigan.
#
# fields is a list of values of foo.field to include in the projection; this
# should be the raw values only, as might be returned by something like
# [db eval {SELECT DISTINCT field FROM foo}] (where db is an sqlite3 handle).
# These will be included in the result set as quoted aliases, and (unlike
# the rest of this proc's arguments) are as safe as sql_name is.
#
# root is the name of the table from which to project all these values; for
# the schema above, you'd pass foo. If applicable this must be quoted: it is
# substituted into the query with blithe disregard. The author expects both
# projecting from subqueries and Bobby Tables shenanigans to work as
# expected/feared. The whole thing will be aliased as "root".
#
# record_key is a column name to be projected as the pseudo-key, as in
# foo.record_key above. This should be quoted as appropriate; an arbitrary
# expression will not work, since it is substituted in a projection, as a
# field of "root", and in a GROUP BY clause.
#
# fieldexpr is an SQL expression to be projected as the column name in the
# query; that is, 'SELECT DISTINCT $fieldexpr' should return some superset of
# the elements of the $fields parameter. Would be "field" for foo above.
#
# valexpr is an SQL expression to be projected as a column value in the query;
# that is, the column named `spam` in the final query will contain the values
# of something like `SELECT $valexpr FROM $root WHERE $fieldexpr = 'spam'`.
# Woudl be "val" for foo above.
#
# where is the expression to be used in the WHERE clause for the whole query;
# for example one could limit it to a certain subset of record_keys in foo.
# above. Defaults to TRUE.
#
# parser is an SQLite database handle, which must support the JSON1 extension.
# If not specified, this proc will attempt to set up its own.
#
# Requires SQLite with JSON1 enabled. The generated query uses SQLite's JSON1
# JSON_GROUP_OBJECT function; trivial modification to allow the use of
# other RDBMSes' object-yielding aggregates in its place is left as an
# exercise to the cargo-cultist.
proc kv2table {projection fields root record_key fieldexpr valexpr {where {TRUE}} {parser {}} } {
	set teardown 0
	if {$parser eq {}} {
		set teardown 1
		set version [package require sqlite3]
		set parser [gensym]
		sqlite3 $parser :memory:
		make_sane $parser $version
	}

	set sql [subst -nocommands \
		{SELECT DISTINCT}
	]

	foreach field $fields {
		set sqlfield [cargocult::sql_name $field]
		set jsonfield [$parser onecolumn {SELECT JSON_QUOTE(:field)}]
		lappend projection [subst -nocommands {JSON_EXTRACT("objectified"."obj", '\$.$jsonfield') AS $sqlfield}]
	}

	append sql "\n\t[join $projection ",\n\t"]\n"

	# Indentation is meant to appear correct in the output, not in the source.
	append sql [subst -nocommands -nobackslashes {
FROM
	$root AS "root" JOIN (
		SELECT $record_key AS "key", JSON_GROUP_OBJECT(
			$fieldexpr, $valexpr
		) AS "obj"
		FROM $root
		GROUP BY $record_key
	) AS "objectified" ON (
		"objectified"."key" = "root".$record_key
	)
}]

	append sql "WHERE $where;"

	if {$teardown} {
		$parser close
	}

	return $sql
}

} ;# namespace eval cargocult
