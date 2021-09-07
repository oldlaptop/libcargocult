eval [pkg::create -name cargocult -version 0.2 \
	-source cargocult.tcl \
	-source db.tcl \
	-source io.tcl \
	-source meta.tcl]

eval [pkg::create -name cargocult::tk -version 0.1 \
	-source tk.tcl]
