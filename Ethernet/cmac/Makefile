TOPDIR=$(shell pwd)
SRCDIR=$(TOPDIR)/src
OBJDIR=$(TOPDIR)/project
IPDIR=$(TOPDIR)/scripts/xilinx_ips
TCLDIR=$(TOPDIR)/scripts


common           	= cmac_sync
alveou50_board 		= cmac_ALVEOu50_0
alveou200_board 	= cmac_ALVEOu200_0 cmac_ALVEOu200_1
alveou250_board 	= cmac_ALVEOu250_0 cmac_ALVEOu250_1
alveou280_board 	= cmac_ALVEOu280_0 cmac_ALVEOu280_1


projects = $(common) $(alveou50_board) $(alveou200_board) $(alveou250_board) $(alveou280_board)
#projects = $(common) $(alveou280_board)

projects : create_project_folder  $(projects)
all: projects

$(projects) : % : $(OBJDIR)/%/component.xml
	@echo -e "\e[94mIP Completed: $@\e[39m"

alveou50 : create_project_folder $(common) $(alveou50_board)
$(alveou50) : % : $(OBJDIR)/%/component.xml
	@echo -e "\e[94mIP Completed: $@\e[39m"

alveou200 : create_project_folder $(common) $(alveou200_board)
$(alveou200) : % : $(OBJDIR)/%/component.xml
	@echo -e "\e[94mIP Completed: $@\e[39m"

alveou250 : create_project_folder $(common) $(alveou250_board)
$(alveou250) : % : $(OBJDIR)/%/component.xml
	@echo -e "\e[94mIP Completed: $@\e[39m"

alveou280 : create_project_folder $(common) $(alveou280_board)
$(alveou280) : % : $(OBJDIR)/%/component.xml
	@echo -e "\e[94mIP Completed: $@\e[39m"

clean:
	rm -rf vivado*.log vivado*.jou file* *.bak synlog.tcl .Xil fsm_encoding.os

distclean: clean
	rm -rf $(OBJDIR)

.PHONY: create_project_folder
create_project_folder:
	./patch_cmac_files.sh
	@mkdir -p project


CMAC_DEPENDENCES := $(SRCDIR)/cmac/cmac_connector_wrapper.sv \
		$(SRCDIR)/cmac/cmac_connector.sv \
		$(SRCDIR)/cmac/cmac_lbus2axi.v \
		$(SRCDIR)/cmac/cmac_lbus_aligner.sv \
		$(SRCDIR)/cmac/cmac_lbus_aligned_2_axi.sv \
		$(SRCDIR)/cmac/cmac_axi2lbus.sv \
		$(SRCDIR)/common/types.svh \
		$(IPDIR)/lbus_fifo.tcl \
		$(IPDIR)/axi_fifo.tcl

CMAC_UPLUS_DEPENDENCES:= $(TCLDIR)/cmac_uplus_wrapper.tcl \
		$(SRCDIR)/cmac/cmac_uplus_wrapper.sv \
		$(IPDIR)/cmac_uplus.tcl

$(OBJDIR)/cmac_ALVEOu50_%/component.xml: current_objective=$(subst $(OBJDIR)/cmac_ALVEOu50_,,$(subst /component.xml,,$@))
$(OBJDIR)/cmac_ALVEOu50_%/component.xml: board_name=$(subst $(OBJDIR)/cmac_,,$(subst _$(current_objective)/component.xml,,$@))
$(OBJDIR)/cmac_ALVEOu50_%/component.xml: $(CMAC_DEPENDENCES) $(CMAC_UPLUS_DEPENDENCES)
	@echo "Board name $(board_name)"
	rm -rf  $(OBJDIR)/cmac_ALVEOu50_$(current_objective)
	vivado -notrace -mode batch -source $(TCLDIR)/cmac_uplus_wrapper.tcl -tclargs --origin_dir $(TOPDIR) --integrated_qsfp $(current_objective) --board ALVEO-U50

$(OBJDIR)/cmac_ALVEOu200_%/component.xml: current_objective=$(subst $(OBJDIR)/cmac_ALVEOu200_,,$(subst /component.xml,,$@))
$(OBJDIR)/cmac_ALVEOu200_%/component.xml: $(CMAC_DEPENDENCES) $(CMAC_UPLUS_DEPENDENCES)
	rm -rf  $(OBJDIR)/cmac_ALVEOu200_$(current_objective)
	vivado -notrace -mode batch -source $(TCLDIR)/cmac_uplus_wrapper.tcl -tclargs --origin_dir $(TOPDIR) --integrated_qsfp $(current_objective) --board ALVEO-U200


$(OBJDIR)/cmac_ALVEOu250_%/component.xml: current_objective=$(subst $(OBJDIR)/cmac_ALVEOu250_,,$(subst /component.xml,,$@))
$(OBJDIR)/cmac_ALVEOu250_%/component.xml: $(CMAC_DEPENDENCES) $(CMAC_UPLUS_DEPENDENCES)
	rm -rf  $(OBJDIR)/cmac_ALVEOu250_$(current_objective)
	vivado -notrace -mode batch -source $(TCLDIR)/cmac_uplus_wrapper.tcl -tclargs --origin_dir $(TOPDIR) --integrated_qsfp $(current_objective) --board ALVEO-U250

$(OBJDIR)/cmac_ALVEOu280_%/component.xml: current_objective=$(subst $(OBJDIR)/cmac_ALVEOu280_,,$(subst /component.xml,,$@))
$(OBJDIR)/cmac_ALVEOu280_%/component.xml: $(CMAC_DEPENDENCES) $(CMAC_UPLUS_DEPENDENCES)
	rm -rf  $(OBJDIR)/cmac_ALVEOu280_$(current_objective)
	vivado -notrace -mode batch -source $(TCLDIR)/cmac_uplus_wrapper.tcl -tclargs --origin_dir $(TOPDIR) --integrated_qsfp $(current_objective) --board ALVEO-U280


cmac_sync_recursive_dependencies := $(shell find $(SRCDIR)/cmac_sync -print)
$(OBJDIR)/cmac_sync/component.xml: $(cmac_sync_recursive_dependencies) \
								   $(TCLDIR)/cmac_sync.tcl \
								   $(SRCDIR)/common/types.svh \
								   $(patch_example_files)
	rm -rf 	$(OBJDIR)/cmac_sync
	vivado -notrace -mode batch -source $(TCLDIR)/cmac_sync.tcl -tclargs $(TOPDIR)


.PHONY: list help
list:
	@(make -rpn | sed -n -e '/^$$/ { n ; /^[^ .#][^% ]*:/p ; }' | sort | egrep --color '^[^ ]*:' )


help:
	@echo "Different projects can be created from this Makefile. So be patient and study the different possibilities before getting hands into the project."
	@echo ""
	@echo "The basic starting point is getting used to the defined targets. They can be stated with the command:"
	@echo -e "    \e[94mmake list\e[39m"
	@echo ""
	@echo "The basic usage of this makefile is:"
	@echo -e " 1) Create the IPs"
	@echo -e "    \e[94mmake $(projects)\e[39m"
	@echo ""
	@echo "Remember that you can always review this help with"
	@echo -e "    \e[94mmake help\e[39m"
