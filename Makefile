.POSIX:

PREFIX = /usr/local
LIBPATH = $(PREFIX)/lib/tcl

CARGO = pkgIndex.tcl cargocult.tcl db.tcl fs.tcl io.tcl math.tcl meta.tcl tdbc.tcl tk.tcl widgets.tcl

install:
	mkdir -p $(LIBPATH)/libcargocult
	cp $(CARGO) $(LIBPATH)/libcargocult
