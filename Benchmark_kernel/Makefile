.PHONY: help

help:
	@echo "Makefile Usage:"
	@echo "  make all DEVICE=<FPGA platform>"
	@echo "      Command to generate the xo for specified device."
	@echo "      By default, DEVICE=xilinx_u280_xdma_201920_3"
	@echo ""
	@echo "  make clean "
	@echo "      Command to remove the generated non-hardware files."
	@echo ""
	@echo "  make distclean"
	@echo "      Command to remove all the generated files."
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
KRNL_NAME_HDL := traffic_generator
KRNL_NAME_HLS := collector
SUBMODULENAME = 100G-fpga-network-stack-core

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := _x.$(XSA)
VIVADO := $(XILINX_VIVADO)/bin/vivado
VPP := $(XILINX_VITIS)/bin/v++
CLFLAGS += -t hw --platform $(DEVICE) --save-temps

BINARY_HLD_OBJS = $(TEMP_DIR)/${KRNL_NAME_HDL}.xo
BINARY_HLS_OBJS = $(TEMP_DIR)/${KRNL_NAME_HLS}.xo

.PHONY: all clean cleanall 
all: check-devices check-vivado check-vitis $(BINARY_HLD_OBJS) $(BINARY_HLS_OBJS)


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou

distclean: clean
	rm -rf build_dir*
	rm -rf ./tmp_$(KRNL_NAME_HDL)* ./packaged_kernel* 
	rm -rf _x.* *.str
	rm -rf .Xil


$(TEMP_DIR)/${KRNL_NAME_HDL}.xo:
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -source gen_xo.tcl -notrace -tclargs $@ ${KRNL_NAME_HDL} $(XSA)

# Remove $(TEMP_DIR)/ and .xo from the target name and store the result in current_kernel
$(TEMP_DIR)/$(KRNL_NAME_HLS).xo: current_kernel=$(subst $(TEMP_DIR)/,,$(subst .xo,,$@))
$(TEMP_DIR)/$(KRNL_NAME_HLS).xo:
	$(VPP) $(CLFLAGS) -k $(current_kernel) -c -o $@ src/$(current_kernel).cpp


check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

#Checks for XILINX_VIVADO
check-vivado:
ifndef XILINX_VIVADO
	$(error XILINX_VIVADO variable is not set, please set correctly and rerun)
endif

#Checks for XILINX_VITIS
check-vitis:
ifndef XILINX_VITIS
	$(error XILINX_VITIS variable is not set, please set correctly and rerun)
endif