#include "xtlm.h"
#include "xtlm_ap_ctrl.h"
#include "ipc2axis_socket.h"
#include "axis2ipc_socket.h"

class cmac : public xsc::xtlm_ap_ctrl_none {
    enum {
        REG_MEM_SIZE = 8192
    };
    public:
        SC_HAS_PROCESS(cmac);
        cmac(sc_module_name name, xsc::common_cpp::properties& _properties);
        ~cmac();

        //! Declare interfaces..
        xtlm::xtlm_aximm_target_socket* s_axi_control_rd_socket;
        xtlm::xtlm_aximm_target_socket* s_axi_control_wr_socket;

        xtlm::xtlm_axis_target_socket *in_socket;
        xtlm::xtlm_axis_target_socket_util *in_util;
        xtlm::xtlm_axis_initiator_socket *out_socket;
        xtlm::xtlm_axis_initiator_socket_util *out_util;
    private:
    	xsc::ipc2axis_socket *ipc2axis_socket;
    	xsc::axis2ipc_socket *axis2ipc_socket;
        void ipc2axis_receive();
        void axis2ipc_send();
	    void send_response();
        std::string get_ipi_name(std::string s);
        sc_core::sc_event trigger_till_sock_connected; 
        unsigned int stream_width_bytes;

        void kernel_config_write();
        void kernel_status_read();

        //axilite memory and args overlapped onto it
        unsigned char reg_mem[REG_MEM_SIZE];
        uint32_t*     kernel_args;

        xtlm::xtlm_aximm_target_wr_socket_util*  s_axi_control_wr_util;
        xtlm::xtlm_aximm_target_rd_socket_util*  s_axi_control_rd_util;

        void log(std::string msg);
};