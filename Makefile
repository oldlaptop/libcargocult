.POSIX:

PREFIX = /usr/local
LIBPATH = $(PREFIX)/lib/tcl

CARGO = pkgIndex.tcl cargocult.tcl db.tcl io.tcl tk.tcl

install:
	mkdir -p $(LIBPATH)/libcargocult
	cp $(CARGO) $(LIBPATH)/libcargocult
