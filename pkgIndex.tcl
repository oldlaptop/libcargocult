eval [pkg::create -name cargocult -version 0.5 \
	-source cargocult.tcl \
	-source db.tcl \
	-source fs.tcl \
	-source io.tcl \
	-source math.tcl \
	-source meta.tcl]

eval [pkg::create -name cargocult::tdbc -version 0.1 \
	-source tdbc.tcl]

eval [pkg::create -name cargocult::tk -version 0.2 \
	-source tk.tcl]

eval [pkg::create -name cargocult::widgets -version 0.1 \
	-source widgets.tcl]
