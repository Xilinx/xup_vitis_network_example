#include <cmac.h>

class cmac_0 : public cmac {
    public:
        SC_HAS_PROCESS(cmac_0);
        cmac_0(sc_module_name name, xsc::common_cpp::properties& _properties) : cmac(name, _properties) {}
        ~cmac_0() {}

        // interface-specific dummy ports
        sc_in<bool> gt_refclk0_p;
        sc_in<bool> gt_refclk0_n;
};
