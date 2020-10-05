# This script patches the cmac_uplus files, in order to be independent and provide a clear implementation

mkdir src/patch_files -p

for i in `seq 0 1`;
do
	# Create a copy of the file in each folder
	cp src/cmac/cmac_uplus_wrapper.sv /tmp/aux.txt
	# Change core name
	sed -i -e 's/module\ cmac_wrapper\ #(/module\ cmac_wrapper_'$i'\ #(/g' /tmp/aux.txt
	sed -i -e 's/cmac_uplus_0\ cmac_i\ (/cmac_uplus_'$i'\ cmac_'$i'\ (/g' /tmp/aux.txt
	mv /tmp/aux.txt src/patch_files/cmac_uplus_wrapper_$i.sv
	
	# Create a copy of the file in each folder
	cp src/cmac/cmac_connector_wrapper.sv /tmp/aux.txt
	# Change core name
	sed -i -e 's/module\ cmac_connector_wrapper\ #(/module\ cmac_connector_wrapper_'$i'\ #(/g' /tmp/aux.txt
	sed -i -e 's/cmac_connector\ #(/cmac_connector_'$i'\ #(/g' /tmp/aux.txt
	mv /tmp/aux.txt src/patch_files/cmac_connector_wrapper_$i.sv

	# Create a copy of the file in each folder
	cp src/cmac/cmac_connector.sv /tmp/aux.txt
	# Change core name
	sed -i -e 's/module\ cmac_connector\ #(/module\ cmac_connector_'$i'\ #(/g' /tmp/aux.txt
	sed -i -e 's/cmac_wrapper\ #(/cmac_wrapper_'$i'\ #(/g' /tmp/aux.txt
	mv /tmp/aux.txt src/patch_files/cmac_connector_$i.sv

done 
