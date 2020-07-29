.PHONY: help

help:
	@echo "Makefile Usage:"
	@echo "  make all DEVICE=<FPGA platform> INTERFACE=<CMAC Interface> DESIGN=<design name>"
	@echo "      Command to generate the xo for specified device and Interface."
	@echo "      By default, DEVICE=xilinx_u280_xdma_201920_3, INTERFACE=0  DESIGN=benchmark"
	@echo "      DESIGN also supports the string basic"
	@echo ""
	@echo "  make clean "
	@echo "      Command to remove the generated non-hardware files."
	@echo ""
	@echo "  make distclean"
	@echo "      Command to remove all the generated files."
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
INTERFACE ?= 0
XCLBIN_NAME ?= xup_vitis_networking_if$(INTERFACE)
DESIGN ?= benchmark

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := _x.$(XSA)
VPP := $(XILINX_VITIS)/bin/v++
CLFLAGS += -t hw --platform $(DEVICE) --save-temps

BUILD_DIR := ./$(DESIGN).intf$(INTERFACE).$(XSA)
BINARY_CONTAINERS = $(BUILD_DIR)/${XCLBIN_NAME}.xclbin

NETLAYERDIR = NetLayers/
CMACDIR     = Ethernet/
KERNELDIR   = Kernels/
BENCHMARDIR = Benchmark_kernel/

NETLAYERHLS = 100G-fpga-network-stack-core

POSTSYSLINKTCL ?= $(shell readlink -f ./post_sys_link.tcl)
CMAC_IP_FOLDER ?= $(shell readlink -f ./$(CMACDIR)/cmac)


LIST_XO = $(NETLAYERDIR)$(TEMP_DIR)/networklayer.xo

CONFIGFLAGS := --config configuration_$(DESIGN)_if$(INTERFACE).tmp.ini

# Include cmac kernel depending on the interface
ifeq (3,$(INTERFACE))
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_0.xo
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_1.xo
else
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_$(INTERFACE).xo
endif

# Include application kernels depending on the design
ifeq (benchmark,$(DESIGN))
	LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/traffic_generator.xo
	LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/collector.xo
else
	LIST_XO += $(KERNELDIR)$(TEMP_DIR)/krnl_mm2s.xo
	LIST_XO += $(KERNELDIR)$(TEMP_DIR)/krnl_s2mm.xo
endif

# Linker params
# Linker userPostSysLinkTcl param
ifeq (u250,$(findstring u250, $(DEVICE)))
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_noHMB)
endif
ifeq (u280,$(findstring u280, $(DEVICE)))
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_HMB)
endif

LIST_REPOS := --user_ip_repo_paths $(CMAC_IP_FOLDER)
LIST_REPOS += --user_ip_repo_paths $(HLS_IP_FOLDER)


.PHONY: all clean distclean 
all: check-devices check-vitis check-xrt create-conf-file $(BINARY_CONTAINERS)

# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou *.str

distclean: clean
	rm -rf _x* *.tmp.ini .Xil benchmark*/ basic*/ .ipcache/


# Building kernel
$(BUILD_DIR)/${XCLBIN_NAME}.xclbin:
	mkdir -p $(BUILD_DIR)
	make -C $(CMACDIR) all DEVICE=$(DEVICE) INTERFACE=$(INTERFACE)
	make -C $(NETLAYERDIR) all DEVICE=$(DEVICE)
	make -C $(KERNELDIR) all DEVICE=$(DEVICE)
	make -C $(BENCHMARDIR) all DEVICE=$(DEVICE) -j2
	$(VPP) $(CLFLAGS) $(CONFIGFLAGS) --temp_dir $(BUILD_DIR) -l -o'$@' $(LIST_XO) $(LIST_REPOS) -j 8 
	#--dk chipscope:traffic_generator_$(INTERFACE):S_AXIS_n2k \
	#--dk chipscope:traffic_generator_$(INTERFACE):M_AXIS_k2n \
	#--dk chipscope:cmac_$(INTERFACE):M_AXIS \
	#--dk chipscope:cmac_$(INTERFACE):S_AXIS
	#--dk chipscope:collector_$(INTERFACE):SUMMARY \

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
	cp config_files/connectivity_$(DESIGN)_if$(INTERFACE).ini configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "[advanced]" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "param=compiler.userPostSysLinkOverlayTcl=$(POSTSYSLINKTCL)" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "#param=compiler.worstNegativeSlack=-2" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini

