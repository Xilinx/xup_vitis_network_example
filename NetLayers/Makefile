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
MAX_SOCKETS ?= 16

ifeq ($(shell test $(MAX_SOCKETS) -gt 63; echo $$?),0)
    $(error Error: maximum number of sockets is 63)
endif

XSA := $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
TEMP_DIR := ./_x.$(XSA)
VIVADO := $(XILINX_VIVADO)/bin/vivado

UDP_THEIR_IP_OFFSET = 0x820
UDP_THEIR_PORT_OFFSET = $(shell printf "0x%04X\n" $$(($(UDP_THEIR_IP_OFFSET) + 8*$(MAX_SOCKETS))))
UDP_MY_PORT_OFFSET = $(shell printf "0x%04X\n" $$(($(UDP_THEIR_PORT_OFFSET) + 8*$(MAX_SOCKETS))))
UDP_VALID_OFFSET = $(shell printf "0x%04X\n" $$(($(UDP_MY_PORT_OFFSET) + 8*$(MAX_SOCKETS))))

NETLAYER_OBJS = $(TEMP_DIR)/${KRNL_NAME}.xo
CLOCK_FREQ = 322265624

ifeq (u5,$(findstring u5, $(DEVICE)))
	SUBMODULETARGET = hbm
else ifeq (u280,$(findstring u280, $(DEVICE)))
	SUBMODULETARGET = hbm
else ifeq (u2,$(findstring u2, $(DEVICE)))
	SUBMODULETARGET = nohbm
else ifeq (vck5000,$(findstring vck5000, $(DEVICE)))
	SUBMODULETARGET = versalaicore
else ifeq (v80,$(findstring v80, $(DEVICE)))
	SUBMODULETARGET = versalhbm
	CLOCK_FREQ = 390998840
endif

.PHONY: all clean cleanall
all: check-devices check-vivado $(NETLAYER_OBJS)


# Cleaning stuff
clean:
	rm -rf *v++* *.log *.jou kernel.xml

distclean: clean
	rm -rf build_dir*
	rm -rf ./tmp_$(KRNL_NAME)* ./packaged_kernel*
	rm -rf _x.* *.str
	rm -rf .Xil

distcleanall: distclean
	make -C $(SUBMODULENAME) distclean


kernel.xml:
	sed -i 's/define NUMBER_SOCKETS 16/define NUMBER_SOCKETS $(MAX_SOCKETS)/' ./$(SUBMODULENAME)/hls/UDP/udp.hpp
	sed -i 's/port=numberSockets/port=numberSockets offset=0x10/' ./$(SUBMODULENAME)/hls/UDP/udp.cpp
	cat ./template.xml | sed 's/UDP_TP_PLACEHOLDER/$(UDP_THEIR_PORT_OFFSET)/' \
	                   | sed 's/UDP_MP_PLACEHOLDER/$(UDP_MY_PORT_OFFSET)/' \
	                   | sed 's/UDP_VL_PLACEHOLDER/$(UDP_VALID_OFFSET)/' > ./kernel.xml

clock-freq:
	sed -i 's/322265624/$(CLOCK_FREQ)/' ./src/performance_debug_reg.v;\

$(TEMP_DIR)/${KRNL_NAME}.xo: clock-freq kernel.xml package_netlayer.tcl src/*.v src/*.vhd
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