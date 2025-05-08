# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

set words [split $device "_"]
set board [lindex $words 1]

if {[string first "u55n" ${board}] != -1} {
    set proj_part "xcu55n-fsvh2892-2L-e"
} elseif {[string first "u50" ${board}] != -1} {
    set proj_part "xcu50-fsvh2104-2-e"
} elseif {[string first "u55c" ${board}] != -1} {
    set proj_part "xcu55c-fsvh2892-2L-e"
} elseif {[string first "u200" ${board}] != -1} {
    set proj_part "xcu200-fsgd2104-2-e"
} elseif {[string first "u250" ${board}] != -1} {
    set proj_part "xcu250-figd2104-2L-e"
} elseif {[string first "u280" ${board}] != -1} {
    set proj_part "xcu280-fsvh2892-2L-e"
} elseif {[string first "vck5000" ${board}] != -1} {
    set proj_part "xcvc1902-vsva2197-2MP-e-S"
} elseif {[string first "v80" ${board}] != -1} {
    set proj_part "xcv80-lsva4737-2MHP-e-S"
} else {
    catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "unsupported device: ${device}"}
    return 1
}
