.POSIX:

.SUFFIXES: .sng .png .png_b64

# Utility targets: `make foo.png_b64` converts an SNG source file into base64
# suitable for inclusion inline in a Tcl source file. For those unfamiliar with
# SNG: http://sng.sf.net
.sng.png:
	sng $<
.png.png_b64:
	base64 $< | tee $@

PREFIX = /usr/local
LIBPATH = $(PREFIX)/lib/tcl

CARGO = pkgIndex.tcl cargocult.tcl db.tcl fs.tcl io.tcl math.tcl meta.tcl tdbc.tcl tk.tcl widgets.tcl

install:
	mkdir -p $(LIBPATH)/libcargocult
	cp $(CARGO) $(LIBPATH)/libcargocult

install_magicsplat.tclapp: install_magicsplat.tclapp.in
	<$? sed "s/@CARGO@/$(CARGO)/" >$@

# Windows-"friendly" source bundle
libcargocult.zip: install_magicsplat.tclapp $(CARGO)
	zip $@ $?
