# TDBC-related cargo.

package require tdbc

namespace eval cargocult {

# SQLite-style prepared statement cache for TDBC. The constructor expects an
# open tdbc::connection handle. The primary entry point (as for SQLite) is the
# eval method, which functions vaguely like SQLite's [$db eval]. No interface
# for managing the cache manually yet exists; for example, if some outside force
# closes its prepared statements, or the database connection goes away, or some
# other disaster occurs, the only recourse is to destroy and recreate the cache.
#
# Most tdbc::connection methods not related to SQL execution or statement
# and resultset management are forwarded to the underlying connection for
# convenience.
oo::class create statementcache {
	variable connection
	variable statements

	constructor {new_connection} {
		set connection $new_connection
		set statements [dict create]

		foreach method {
			foreignkeys
			primarykeys
			tables
			columns
			begintransaction
			commit
			rollback
			transaction
		} {
			oo::objdefine [self] forward \
				$method $connection $method
		}
	}

	# Closes any prepared statements managed by the cache, but leaves the
	# connection intact.
	destructor {
		if {[info exists statements]} {
			foreach obj [dict values $statements] {
				$obj close
			}
		}
	}

	# Evaluates $sql against the database, through the cache of prepared
	# statements. If $sql has never been evaluated through this method
	# on this cache object before, a statement is prepared against the
	# database with that body and added to the cache. If it *has* been
	# evaluated before, a statement will be in the cache, and will be used
	# instead of preparing a new one.
	#
	# If no arguments other than $sql are passed, returns the result of
	# calling the prepared statement's allrows method in the caller's scope.
	# Otherwise, returns the result of calling the statement's foreach
	# method, passing all arguments to it unchanged (all but the last before
	# the /sqlcode/ argument, and the last after it).
	#
	# Fuller emulation of either SQLite [$db eval] or TDBC [$db foreach]
	# syntax might happen if the author someday needs it.
	method eval {sql args} {
		if {![dict exists $statements $sql]} {
			dict set statements $sql [$connection prepare $sql]
		}
		if {[llength $args] == 0} {
			uplevel 1 [list [dict get $statements $sql] allrows]
		} else {
			uplevel 1 [list [dict get $statements $sql] foreach {*}[lrange $args 0 end-1] $sql [lindex $args end]]
		}
	}

	# Closes the associated database connection and destroys the cache.
	method close {} {
		$connection close
		# Statements have been cleaned up, we can fry the references...
		set statements {}

		# ...so the destructor won't try to destroy them itself.
		my destroy
	}
}

} ;# namespace eval cargocult
