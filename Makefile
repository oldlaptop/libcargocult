.POSIX:

PREFIX = /usr/local
LIBPATH = $(PREFIX)/lib/tcl

CARGO = pkgIndex.tcl cargocult.tcl db.tcl fs.tcl io.tcl math.tcl meta.tcl tk.tcl

install:
	mkdir -p $(LIBPATH)/libcargocult
	cp $(CARGO) $(LIBPATH)/libcargocult
