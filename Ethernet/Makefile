.PHONY: help

help:
	@echo "Makefile Usage:"
	@echo "  make all DEVICE=<FPGA platform> INTERFACE=<CMAC Interface>"
	@echo "      Command to generate the xo for specified device and Interface."
	@echo "      By default, DEVICE=xilinx_u280_xdma_201920_3 and INTERFACE=0"
	@echo "      INTERFACE can be 0, 1 or 3 (both interface 0 and 1 simultaneously)"
	@echo ""
	@echo "  make clean "
	@echo "      Command to remove the generated non-hardware files."
	@echo ""
	@echo "  make distclean"
	@echo "      Command to remove all the generated files."
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
INTERFACE ?= 0
KRNL_NAME = cmac

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := _x.$(XSA)
VIVADO := $(XILINX_VIVADO)/bin/vivado


BINARY_NETLAYER_OBJS := $(TEMP_DIR)/${KRNL_NAME}_$(INTERFACE).xo

#Overwrite targets when INTERFACE equals 3
ifeq (3,$(INTERFACE))
	BINARY_NETLAYER_OBJS := $(TEMP_DIR)/${KRNL_NAME}_0.xo
	BINARY_NETLAYER_OBJS += $(TEMP_DIR)/${KRNL_NAME}_1.xo
endif

.PHONY: all clean distclean 
all: check-devices check-vivado check-interface $(BINARY_NETLAYER_OBJS)  


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou 

distclean: clean
	rm -rf build_dir*
	rm -rf _x.* kernel_*.xml src/cmac_top*.v *.str
	rm -rf ./tmp_cmac* ./packaged_kernel* .Xil
	rm -rf component.xml xgui/


$(TEMP_DIR)/${KRNL_NAME}%.xo: current_interface=$(subst $(TEMP_DIR)/${KRNL_NAME}_,,$(subst .xo,,$@))
$(TEMP_DIR)/${KRNL_NAME}%.xo: template.xml package_cmac.tcl bd_cmac.tcl src/*.v
	mkdir -p $(TEMP_DIR)
	./duplicate_patch.sh
	$(VIVADO) -mode batch -source package_cmac.tcl -notrace -tclargs $@ ${KRNL_NAME}_$(current_interface) $(XSA) $(current_interface)


check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

#Checks for XILINX_VIVADO
check-vivado:
ifndef XILINX_VIVADO
	$(error XILINX_VIVADO variable is not set, please set correctly and rerun)
endif

check-interface:
ifeq (2,$(INTERFACE))
	$(error INTERFACE cannot value 2, to use generate both interfaces xo use INTERFACE=3)
endif