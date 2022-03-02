package provide cargocult 0.4

namespace eval cargocult {
	# Some cargo expects tcl::mathop and tcl::mathfunc.
	namespace import ::tcl::mathop::*
	namespace import ::tcl::mathfunc::*
}
