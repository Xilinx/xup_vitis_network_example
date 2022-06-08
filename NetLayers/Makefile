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
	@echo "  make distcleanall"
	@echo "      Command to remove all the generated in the current directory and one level down"
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
KRNL_NAME := networklayer
SUBMODULENAME = 100G-fpga-network-stack-core

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := ./_x.$(XSA)
VIVADO := $(XILINX_VIVADO)/bin/vivado

NETLAYER_OBJS = $(TEMP_DIR)/${KRNL_NAME}.xo

ifeq (u5,$(findstring u5, $(DEVICE)))
	SUBMODULETARGET = hbm
else ifeq (u280,$(findstring u280, $(DEVICE)))
	SUBMODULETARGET = hbm
else ifeq (u2,$(findstring u2, $(DEVICE)))
	SUBMODULETARGET = nohbm
else ifeq (vck5000,$(findstring vck5000, $(DEVICE)))
	SUBMODULETARGET = versalaicore
endif

.PHONY: all clean cleanall
all: check-devices check-vivado $(NETLAYER_OBJS)


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou

distclean: clean
	rm -rf build_dir*
	rm -rf ./tmp_$(KRNL_NAME)* ./packaged_kernel*
	rm -rf _x.* *.str
	rm -rf .Xil

distcleanall: distclean
	make -C $(SUBMODULENAME) distclean


$(TEMP_DIR)/${KRNL_NAME}.xo: kernel.xml package_netlayer.tcl src/*.v src/*.vhd
	mkdir -p $(TEMP_DIR)
	make -C $(SUBMODULENAME) $(SUBMODULETARGET)
	$(VIVADO) -mode batch -source package_netlayer.tcl -notrace -tclargs $@ ${KRNL_NAME} $(XSA)

check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

#Checks for XILINX_VIVADO
check-vivado:
ifndef XILINX_VIVADO
	$(error XILINX_VIVADO variable is not set, please set correctly and rerun)
endif