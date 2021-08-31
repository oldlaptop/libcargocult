# Metalinguistic cargo that doesn't obviously belong in another category.

namespace eval cargocult {

# Generate a unique symbol, useful for ephemeral, dynamically generated names
namespace eval gensym { variable n 0 }
proc gensym {{prefix sym}} { return ${prefix}[incr gensym::n] }

} ;# namespace eval cargocult
