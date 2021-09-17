# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

set words [split $device "_"]
set board [lindex $words 1]

if {[string first "u50" ${board}] != -1} {
    set projPart "xcu50-fsvh2104-2L-e"
} elseif {[string first "u55" ${board}] != -1} {
    set projPart "xcu55c-fsvh2892-2L-e"
} elseif {[string first "u200" ${board}] != -1} {
    set projPart "xcu200-fsgd2104-2-e"
} elseif {[string first "u250" ${board}] != -1} {
    set projPart "xcu250-figd2104-2L-e"
} elseif {[string first "u280" ${board}] != -1} {
    set projPart "xcu280-fsvh2892-2L-e"
} else {
    catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "unsupported device: ${device}"}
    return 1
}