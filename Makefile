SHELL=/bin/bash

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
	@echo "      Command to remove all the generated files in the current directory"
	@echo ""
	@echo "  make distcleanall"
	@echo "      Command to remove all the generated in the current directory and one level down"
	@echo ""


DEVICE ?= xilinx_u280_xdma_201920_3
INTERFACE ?= 0
DESIGN ?= benchmark
XCLBIN_NAME ?= vnx_$(DESIGN)_if$(INTERFACE)


XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := _x.$(XSA)
VPP := $(XILINX_VITIS)/bin/v++
CLFLAGS += -t hw --platform $(DEVICE) --save-temps

BUILD_DIR := ./$(DESIGN).intf$(INTERFACE).$(XSA)
BINARY_CONTAINERS = $(BUILD_DIR)/${XCLBIN_NAME}.xclbin

NETLAYERDIR = NetLayers/
CMACDIR     = Ethernet/
BASICDIR    = Basic_kernels/
BENCHMARDIR = Benchmark_kernel/

NETLAYERHLS = 100G-fpga-network-stack-core

POSTSYSLINKTCL ?= $(shell readlink -f ./Ethernet/post_sys_link.tcl)
SWITCH_IP_FOLDER ?= $(shell readlink -f ./$(BENCHMARDIR)/packaged_kernel_switch_wrapper_$(XSA))


LIST_XO = $(NETLAYERDIR)$(TEMP_DIR)/networklayer.xo

CONFIGFLAGS := --config configuration_$(DESIGN)_if$(INTERFACE).tmp.ini

# Include cmac kernel depending on the interface
ifeq (3,$(INTERFACE))
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_0.xo
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_1.xo
else
	LIST_XO += $(CMACDIR)$(TEMP_DIR)/cmac_$(INTERFACE).xo
endif

LIST_REPOS = 

# Include application kernels depending on the design
ifeq (benchmark,$(DESIGN))
	LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/traffic_generator.xo
	LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/collector.xo
	LIST_XO += $(BENCHMARDIR)$(TEMP_DIR)/switch_wrapper.xo
	LIST_REPOS += --user_ip_repo_paths $(SWITCH_IP_FOLDER)
else
	LIST_XO += $(BASICDIR)$(TEMP_DIR)/krnl_mm2s.xo
	LIST_XO += $(BASICDIR)$(TEMP_DIR)/krnl_s2mm.xo
endif

# Linker parameters
# Linker userPostSysLinkTcl param
ifeq (u5,$(findstring u5, $(DEVICE)))
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_HMB)
endif
ifeq (u200,$(findstring u200, $(DEVICE)))
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_noHMB)
endif
ifeq (u250,$(findstring u250, $(DEVICE)))
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_noHMB)
endif
ifeq (u280,$(findstring u280, $(DEVICE)))
	HLS_IP_FOLDER  = $(shell readlink -f ./$(NETLAYERDIR)$(NETLAYERHLS)/synthesis_results_HMB)
endif

LIST_REPOS += --user_ip_repo_paths $(HLS_IP_FOLDER)

.PHONY: all clean distclean distcleanall
all: check-devices check-vitis check-xrt check-design check-interface create-conf-file $(BINARY_CONTAINERS)

# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou *.str

distclean: clean
	rm -rf _x* *.tmp.ini .Xil benchmark*/ basic*/ .ipcache/

distcleanall: distclean
	make -C $(NETLAYERDIR) distclean
	make -C $(CMACDIR) distclean
	make -C $(BASICDIR) distclean
	make -C $(BENCHMARDIR) distclean


# Building kernel
$(BUILD_DIR)/${XCLBIN_NAME}.xclbin: $(LIST_XO)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) $(CONFIGFLAGS) --temp_dir $(BUILD_DIR) -l -o'$@' $^ $(LIST_REPOS) -j 8

$(BASICDIR)$(TEMP_DIR)/%.xo: $(BASICDIR)src/*.cpp
	make -C $(BASICDIR) all DEVICE=$(DEVICE) -j3

$(BENCHMARDIR)$(TEMP_DIR)/%.xo: $(BENCHMARDIR)src/*
	make -C $(BENCHMARDIR) all DEVICE=$(DEVICE) -j3

$(CMACDIR)$(TEMP_DIR)/%.xo:
	make -C $(CMACDIR) all DEVICE=$(DEVICE) INTERFACE=$(INTERFACE)

$(NETLAYERDIR)$(TEMP_DIR)/%.xo:
	make -C $(NETLAYERDIR) all DEVICE=$(DEVICE)


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

#Check if the design name is supported
check-design:
	@if [[ ($(DESIGN) != "benchmark") && ($(DESIGN) != "basic") ]]; then\
		echo "DESIGN=$(DESIGN) is not supported!";\
		exit 1;\
	fi

check-interface:
	@if [[ ($(XSA) =~ "u50") && ($(INTERFACE) != 0) ]]; then\
		echo "Platform $(XSA) only has INTERFACE=0!";\
		exit 1;\
	fi
	@if [[ ($(INTERFACE) != 0) && ($(INTERFACE) != 1) && ($(INTERFACE) != 3) ]]; then\
		echo "Interface $(INTERFACE) is not supported in platform $(XSA)!";\
		exit 1;\
	fi

#Create configuration file for current design and settings
create-conf-file:
	cp config_files/connectivity_$(DESIGN)_if$(INTERFACE).ini configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "[advanced]" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "param=compiler.userPostSysLinkOverlayTcl=$(POSTSYSLINKTCL)" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	#echo "param=compiler.worstNegativeSlack=-2" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	#echo "param=compiler.compiler.errorOnHoldViolation=false" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "[vivado]" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	echo "prop=run.impl_1.strategy=Performance_NetDelay_low" >> configuration_$(DESIGN)_if$(INTERFACE).tmp.ini
	@if [[ $(DEVICE) = *"u5"* ]]; then\
		sed -i 's/SLR2/SLR1/g' configuration_$(DESIGN)_if$(INTERFACE).tmp.ini;\
	fi
