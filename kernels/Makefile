.PHONY: help

help:
	@echo "Makefile Usage:"
	@echo "  make all DEVICE=<FPGA platform> kernel_list=\"<list of kernels>"\"
	@echo "      Command to generate the xo for specified device and Interface."
	@echo "      By default, DEVICE=xilinx_u280_xdma_201920_3 and kernel_list=\"krnl_s2mm krnl_mm2s\""
	@echo ""
	@echo "  make clean "
	@echo "      Command to remove the generated non-hardware files."
	@echo ""
	@echo "  make distclean"
	@echo "      Command to remove all the generated files."
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
kernel_list ?= krnl_s2mm krnl_mm2s


XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := _x.$(XSA)
VPP := $(XILINX_VITIS)/bin/v++
CLFLAGS += -t hw --platform $(DEVICE) --save-temps
BINARY_OBJS = $(addprefix $(TEMP_DIR)/, $(addsuffix .xo, $(kernel_list)))


.PHONY: all clean cleanall 
all: check-devices check-vitis check-xrt $(BINARY_OBJS)  


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou

distclean: clean
	rm -rf _x* .Xil

# Remove $(TEMP_DIR)/ and .xo from the target name and store the result in current_kernel
$(TEMP_DIR)/%.xo: current_kernel=$(subst $(TEMP_DIR)/,,$(subst .xo,,$@))
$(TEMP_DIR)/%.xo: 
	$(VPP) $(CLFLAGS) -k $(current_kernel) -c -o $@ src/$(current_kernel).cpp


check-devices:
ifndef DEVICE
	$(error DEVICE not set. Please set the DEVICE properly and rerun. Run "make help" for more details.)
endif

#Checks for XILINX_VITIS
check-vitis:
ifndef XILINX_VITIS
	$(error XILINX_VITIS variable is not set, please set correctly and rerun)
endif

#Checks for XILINX_XRT
check-xrt:
ifndef XILINX_XRT
	$(error XILINX_XRT variable is not set, please set correctly and rerun)
endif