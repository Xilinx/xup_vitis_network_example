.PHONY: help

help:
	@echo "Makefile Usage:"
	@echo "  make all DEVICE=<FPGA platform> INTERFACE=<CMAC Interface> XCLBIN_NAME=<XCLBIN name>"
	@echo "      Command to generate the xo for specified device and Interface."
	@echo "      By default, DEVICE=xilinx_u280_xdma_201920_3, INTERFACE=0 and XCLBIN_NAME=xup_vitis_networking "
	@echo ""
	@echo "  make clean "
	@echo "      Command to remove the generated non-hardware files."
	@echo ""
	@echo "  make distclean"
	@echo "      Command to remove all the generated files."
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
INTERFACE ?= 0
XCLBIN_NAME ?= xup_vitis_networking
DESIGN ?= benchmark

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := _x.$(XSA)
VPP := $(XILINX_VITIS)/bin/v++
CLFLAGS += -t hw --platform $(DEVICE) --save-temps

BUILD_DIR := ./build_dir.intf$(INTERFACE).$(XSA)
BINARY_CONTAINERS = $(BUILD_DIR)/${XCLBIN_NAME}.xclbin

NETLAYERDIR = NetLayers/
CMACDIR     = Ethernet/
KERNELDIR   = Kernels/
BENCHMARDIR = Benchmark_kernel/

NETLAYERHLS = 100G-fpga-network-stack-core

POSTSYSLINKTCL ?= $(shell readlink -f ./post_sys_link.tcl)
CMAC_IP_FOLDER ?= $(shell readlink -f ./$(CMACDIR)/cmac)


LIST_XO = $(NETLAYERDIR)$(TEMP_DIR)/networklayer.xo
#LIST_XO += $(KERNELDIR)$(TEMP_DIR)/krnl_mm2s.xo
#LIST_XO += $(KERNELDIR)$(TEMP_DIR)/krnl_s2mm.xo
LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/traffic_generator.xo
LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/collector.xo

CONFIGFLAGS := --config configuration_if$(INTERFACE).ini

ifeq (3,$(INTERFACE))
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_0.xo
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_1.xo
else
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_$(INTERFACE).xo
endif


# Linker params
# Linker userPostSysLinkTcl param
ifeq (u250,$(findstring u250, $(DEVICE)))
	#CONFIGFLAGS += --config advanced.ini
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_noHMB)
endif
ifeq (u280,$(findstring u280, $(DEVICE)))
	#CONFIGFLAGS += --config advanced.ini
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_HMB)
endif


LIST_REPOS := --user_ip_repo_paths $(CMAC_IP_FOLDER)
LIST_REPOS += --user_ip_repo_paths $(HLS_IP_FOLDER)



.PHONY: all clean distclean 
all: check-devices check-vitis check-xrt create-conf-file $(BINARY_CONTAINERS)


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou

distclean: clean
	rm -rf _x* .Xil ./build_dir* .ipcache/


# Building kernel
$(BUILD_DIR)/${XCLBIN_NAME}.xclbin:
	mkdir -p $(BUILD_DIR)
	#make -C $(CMACDIR) all DEVICE=$(DEVICE) INTERFACE=$(INTERFACE)
	make -C $(NETLAYERDIR) all DEVICE=$(DEVICE)
	#make -C $(KERNELDIR) all DEVICE=$(DEVICE)
	make -C $(BENCHMARDIR) all DEVICE=$(DEVICE) -j2
	$(VPP) $(CLFLAGS) $(CONFIGFLAGS) --temp_dir $(BUILD_DIR) -l -o'$@' $(LIST_XO) $(LIST_REPOS) -j 8 \
	--dk chipscope:collector_1:SUMMARY \
	--dk chipscope:traffic_generator_1:M_AXIS_k2n
#	--dk chipscope:krnl_s2mm_1:n2k
#	--dk chipscope:krnl_mm2s_1:s_axi_control \
#	--dk chipscope:krnl_s2mm_1:s_axi_control \

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

#Create configuration file for current design and settings
create-conf-file:
	cp config_files/connectivity_$(DESIGN)_if$(INTERFACE).ini configuration_if$(INTERFACE).ini
	echo "" >> configuration_if$(INTERFACE).ini
	echo "" >> configuration_if$(INTERFACE).ini
	echo "[advanced]" >> configuration_if$(INTERFACE).ini
	echo "param=compiler.userPostSysLinkOverlayTcl=$(POSTSYSLINKTCL)" >> configuration_if$(INTERFACE).ini
	echo "#param=compiler.worstNegativeSlack=-2" >> configuration_if$(INTERFACE).ini

