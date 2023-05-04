// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include "cmac.h"

#define RETRIGGER_TIME 1000

unsigned int get_uint_reg(unsigned char *buf, unsigned int addr){
    const unsigned int* int_ptr = reinterpret_cast<const unsigned int*>(buf + addr);
    return *int_ptr;
}

void set_uint_reg(unsigned char *buf, unsigned int addr, unsigned int val){
    unsigned int* int_ptr = reinterpret_cast<unsigned int*>(buf + addr);
    int_ptr[0] = val;
}

cmac::cmac(sc_module_name name, xsc::common_cpp::properties& _properties) : xsc::xtlm_ap_ctrl_none(name) {
	padding_mode = _properties.getLongLong("PADDING_MODE");
    loopback = false;
    unsigned int stream_width = _properties.getLongLong("AXIS_TDATA_WIDTH");
	stream_width_bytes = stream_width / 8;

    S_AXILITE_rd_socket = new xtlm::xtlm_aximm_target_socket("rd_socket", 32);
    S_AXILITE_rd_util   = new xtlm::xtlm_aximm_target_rd_socket_util("rd_util", xtlm::aximm::TRANSACTION, 32);
    S_AXILITE_wr_socket = new xtlm::xtlm_aximm_target_socket("wr_socket", 32);
    S_AXILITE_wr_util   = new xtlm::xtlm_aximm_target_wr_socket_util("wr_util", xtlm::aximm::TRANSACTION, 32);
    S_AXILITE_rd_socket->bind(S_AXILITE_rd_util->rd_socket);
    S_AXILITE_wr_socket->bind(S_AXILITE_wr_util->wr_socket);

	S_AXIS_socket = new xtlm::xtlm_axis_target_socket("in", stream_width);
	S_AXIS_util = new xtlm::xtlm_axis_target_socket_util("S_AXIS_util", xtlm::axis::TRANSACTION, stream_width);
	S_AXIS_socket->bind((S_AXIS_util->stream_socket));

	M_AXIS_socket = new xtlm::xtlm_axis_initiator_socket("out", stream_width);
	M_AXIS_util = new xtlm::xtlm_axis_initiator_socket_util("M_AXIS_util", xtlm::axis::TRANSACTION, stream_width);
	M_AXIS_util->stream_socket.bind(*M_AXIS_socket);

	//! Instantiate IPC2AXIS Socket
	ipc2axis_socket = new xsc::ipc2axis_socket("ipc2axis_socket", get_ipi_name(this->name())+"_ingress");
	axis2ipc_socket = new xsc::axis2ipc_socket("axis2ipc_socket", get_ipi_name(this->name())+"_egress");

    memset(reg_mem, 0, REG_MEM_SIZE);

    SC_METHOD(kernel_config_write);
    sensitive << S_AXILITE_wr_util->transaction_available;
    dont_initialize();

    SC_METHOD(kernel_status_read);
    sensitive << S_AXILITE_rd_util->transaction_available;
    dont_initialize();

    SC_METHOD(axis2ipc_send);
    sensitive << S_AXIS_util->transaction_available;
    sensitive << axis2ipc_socket->event(); //! transfer complete
    sensitive << trigger_till_sock_connected; //!Re-trigger after given time
	dont_initialize();

	SC_METHOD(ipc2axis_receive);
	sensitive << ipc2axis_socket->event();
	sensitive << M_AXIS_util->transfer_done;

	SC_METHOD(send_response);
	sensitive << M_AXIS_util->transfer_done;
	dont_initialize();

}

void cmac::log(std::string msg){
    m_ss.str(msg);
    XSC_REPORT_INFO((*m_log), m_name, m_ss.str().c_str());
}

void cmac::ipc2axis_receive()
{
    if(loopback){
        log("In loopback mode, ignoring IPC receive request");
        return;
    }

	if (!M_AXIS_util->is_transfer_done())
	{
        log("transfer done to port OUT");
		return;
	}

	xtlm::axis_payload *payload = ipc2axis_socket->get_payload();
	if (payload != nullptr)
	{
        unsigned int nbytes = payload->get_tdata_length();
        log("HAVE RX PAYLOAD of size "+std::to_string(nbytes));
        unsigned int nbeats = (nbytes + stream_width_bytes - 1) / stream_width_bytes;
		payload->set_n_beats(nbeats);
		M_AXIS_util->transport(payload, SC_ZERO_TIME);
	}
}

void cmac::send_response()
{
    if(!loopback){
        log("Send response to IPC2AXIS socket");
        ipc2axis_socket->send_response();
    }
}

void cmac::axis2ipc_send() 
{
    if(!loopback){
        //When external process is not connected, re-trigger this method until
	    //external process is connected.
        if (!axis2ipc_socket->is_external_proc_connected())
        {
            trigger_till_sock_connected.notify(RETRIGGER_TIME, sc_core::SC_NS);
            log("Send: waiting for external proc to connect");
            return;
        }
        if (!axis2ipc_socket->is_transfer_done())
        {
            log("Send: triggered for unknown reason, IPC transfer not done, returning");
            return;
        }
    }
    if(!S_AXIS_util->is_transaction_available()){
        log("Send: triggered for unknown reason, no payload on S_AXIS, returning");
        return;
    }

	//Get the payload
	xtlm::axis_payload* payload = S_AXIS_util->sample_transaction();
    log("HAVE TX PAYLOAD of size "+std::to_string(payload->get_tdata_length()));

    //TODO process padding
    if(padding_mode == PADDING_60B && payload->get_tdata_length() < 60){
        log("Padding from "+std::to_string(payload->get_tdata_length())+"B to 60B");
    } else if(padding_mode == PADDING_64B && payload->get_tdata_length() < 64){
        log("Padding from "+std::to_string(payload->get_tdata_length())+"B to 64B");
    }

    //do any relevant data forwarding here
    if(loopback){
        unsigned int nbytes = payload->get_tdata_length();
        log("Loopback: HAVE RX PAYLOAD of size "+std::to_string(nbytes));
        unsigned int nbeats = (nbytes + stream_width_bytes - 1) / stream_width_bytes;
		payload->set_n_beats(nbeats);
		M_AXIS_util->transport(payload, SC_ZERO_TIME);
    } else {
        //Send axi stream payload 
        axis2ipc_socket->transport(payload);
        log("Transported TX payload");
    }
}

std::string cmac::get_ipi_name(std::string s){
    s = s.substr(0, s.find_last_of("./")); // Adding "/" to support QUESTA
    s = s.substr(s.find_last_of("./") + 1);
    return s;
}


void cmac::kernel_config_write(){
    xtlm::aximm_payload* trans = S_AXILITE_wr_util->get_transaction();
    unsigned long long addr = trans->get_address() & 0xffff;
    unsigned int data = *(unsigned int*)trans->get_data_ptr();

    if(addr >= REG_MEM_SIZE) {
        m_ss.str("");
        m_ss << "Out of bound address received: 0x" << std::hex << addr;
        XSC_REPORT_ERROR((*m_log), m_name, m_ss.str().c_str());
        return; //! Throw error
    }

    m_ss.str("");
    m_ss << "Writing via axi-lite to   addr 0x" << std::hex << std::setfill('0') << std::setw(8) << addr 
            << " data 0x" << std::setw(8) << data;
    XSC_REPORT_INFO((*m_log), m_name, m_ss.str().c_str());

    memcpy(&reg_mem[addr], trans->get_data_ptr(), trans->get_data_length());

    trans->set_response_status(xtlm::XTLM_OK_RESPONSE);
    sc_core::sc_time delay = SC_ZERO_TIME;
    S_AXILITE_wr_util->send_resp(*trans, delay);

    //check relevant registers for operational status changes
    loopback = (get_uint_reg(reg_mem, cfgaddr_gt_loopback) == 1);
}

void cmac::kernel_status_read(){
    xtlm::aximm_payload* trans = S_AXILITE_rd_util->get_transaction();
    unsigned long long addr = trans->get_address() & 0xffff;

    if(addr >= REG_MEM_SIZE) {
        m_ss.str("");
        m_ss << "Out of bound address received: 0x" << std::hex << addr;
        XSC_REPORT_ERROR((*m_log), m_name, m_ss.str().c_str());
        return; //! Throw    error
    }

    m_ss.str("");
    m_ss << "Reading via axi-lite from addr 0x" << std::hex << std::setfill('0') << std::setw(8) << addr 
            << " data 0x" << std::setw(8) << *(unsigned int*)(&reg_mem[addr]);
    XSC_REPORT_INFO_VERB((*m_log), m_name, m_ss.str().c_str(), DEBUG);

    //set important status registers before the read
    set_uint_reg(reg_mem, cfgaddr_stat_rx_status, axis2ipc_socket->is_external_proc_connected() ? 3 : 2);
    set_uint_reg(reg_mem, cfgaddr_stat_tx_status, 0);

    memcpy(trans->get_data_ptr(), &reg_mem[addr], trans->get_data_length());
    trans->set_response_status(xtlm::XTLM_OK_RESPONSE);
    sc_core::sc_time delay = sc_core::SC_ZERO_TIME;
    S_AXILITE_rd_util->send_data(*trans, delay);
}

cmac::~cmac(){
	delete M_AXIS_util;
	delete M_AXIS_socket;
	delete ipc2axis_socket;
	delete S_AXIS_util;
	delete S_AXIS_socket;
	delete axis2ipc_socket;
    delete S_AXILITE_rd_util;
    delete S_AXILITE_wr_util;
    delete S_AXILITE_rd_socket;
    delete S_AXILITE_wr_socket;
}