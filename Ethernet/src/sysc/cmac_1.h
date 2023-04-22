#include <cmac.h>

class cmac_1 : public cmac {
    public:
        SC_HAS_PROCESS(cmac_1);
        cmac_1(sc_module_name name, xsc::common_cpp::properties& _properties) : cmac(name, _properties) {}
        ~cmac_1() {}

        // interface-specific dummy ports
        sc_in<bool> gt_refclk1_p;
        sc_in<bool> gt_refclk1_n;
};
