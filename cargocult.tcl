package provide cargocult 0.1

namespace eval cargocult {
	# Some cargo expects tcl::mathop and tcl::mathfunc.
	namespace import ::tcl::mathop::*
	namespace import ::tcl::mathfunc::*
}
