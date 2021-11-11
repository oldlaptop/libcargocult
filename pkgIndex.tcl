eval [pkg::create -name cargocult -version 0.3 \
	-source cargocult.tcl \
	-source db.tcl \
	-source fs.tcl \
	-source io.tcl \
	-source math.tcl \
	-source meta.tcl]

eval [pkg::create -name cargocult::tk -version 0.1 \
	-source tk.tcl]
