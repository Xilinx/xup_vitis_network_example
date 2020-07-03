.PHONY: help

help:
	@echo "Makefile Usage:"
	@echo "  make all DEVICE=<FPGA platform> INTERFACE=<CMAC Interface>"
	@echo "      Command to generate the xo for specified device and Interface."
	@echo "      By default, DEVICE=xilinx_u280_xdma_201920_3 and INTERFACE=0"
	@echo ""
	@echo "  make clean "
	@echo "      Command to remove the generated non-hardware files."
	@echo ""
	@echo "  make distclean"
	@echo "      Command to remove all the generated files."
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
INTERFACE := 0
KRNL_NAME := cmac_${INTERFACE}
SUBMODULENAME = cmac

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := ./_x.$(XSA)
VIVADO := $(XILINX_VIVADO)/bin/vivado

BINARY_NETLAYER_OBJS = $(TEMP_DIR)/${KRNL_NAME}.xo


ifeq (u200,$(findstring u50, $(DEVICE)))
	SUBMODULEIPTARGET = alveou50
endif

ifeq (u200,$(findstring u200, $(DEVICE)))
	SUBMODULEIPTARGET = alveou200
endif

ifeq (u250,$(findstring u250, $(DEVICE)))
	SUBMODULEIPTARGET = alveou250
endif

ifeq (u280,$(findstring u280, $(DEVICE)))
	SUBMODULEIPTARGET = alveou280
endif

.PHONY: all clean cleanall 
all: check-devices check-vivado $(BINARY_NETLAYER_OBJS)  


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou

distclean: clean
	rm -rf build_dir*
	rm -rf _x.* kernel_*.xml
	rm -rf ./tmp_cmac* ./packaged_kernel* .Xil


$(TEMP_DIR)/${KRNL_NAME}.xo: template.xml package_kernel.tcl gen_xo.tcl *.v
	mkdir -p $(TEMP_DIR)
	./duplicate_patch.sh
	make -C $(SUBMODULENAME) $(SUBMODULEIPTARGET)
	$(VIVADO) -mode batch -source gen_xo.tcl -notrace -tclargs $@ ${KRNL_NAME} $(XSA) $(INTERFACE)


check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

#Checks for XILINX_VIVADO
check-vivado:
ifndef XILINX_VIVADO
	$(error XILINX_VIVADO variable is not set, please set correctly and rerun)
endif