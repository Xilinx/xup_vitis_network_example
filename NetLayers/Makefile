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
KRNL_NAME := networklayer
SUBMODULENAME = 100G-fpga-network-stack-core

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := ./_x.$(XSA)
VIVADO := $(XILINX_VIVADO)/bin/vivado

BINARY_CMAC_OBJS = $(TEMP_DIR)/${KRNL_NAME}.xo


ifeq (u200,$(findstring u50, $(DEVICE)))
	SUBMODULETARGET = hbm
endif

ifeq (u200,$(findstring u200, $(DEVICE)))
	SUBMODULETARGET = all
endif

ifeq (u250,$(findstring u250, $(DEVICE)))
	SUBMODULETARGET = all
endif

ifeq (u280,$(findstring u280, $(DEVICE)))
	SUBMODULETARGET = hbm
endif

.PHONY: all clean cleanall 
all: check-devices check-vivado $(BINARY_CMAC_OBJS)  


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou

distclean: clean
	rm -rf build_dir*
	rm -rf ./tmp_$(KRNL_NAME)* ./packaged_kernel* 
	rm -rf _x.* *.str
	rm -rf .Xil


$(TEMP_DIR)/${KRNL_NAME}.xo: kernel.xml package_kernel.tcl gen_xo.tcl src/*.v src/*.vhd
	mkdir -p $(TEMP_DIR)
	make -C $(SUBMODULENAME) $(SUBMODULETARGET)
	$(VIVADO) -mode batch -source gen_xo.tcl -notrace -tclargs $@ ${KRNL_NAME} $(XSA)

check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

#Checks for XILINX_XRT
check-vivado:
ifndef XILINX_VIVADO
	$(error XILINX_VIVADO variable is not set, please set correctly and rerun)
endif