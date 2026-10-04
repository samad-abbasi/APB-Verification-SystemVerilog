`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_agent extends uvm_agent;

`uvm_component_utils(apb_agent)

function new(string name ="apb_agent", uvm_component parent=null);
super.new(name,parent);
endfunction


apb_driver m_drv; 
apb_monitor m_mon;
apb_sequencer m_sqr;

//uvm_sequence #(fifo_item) sqr; for direct calling

virtual function void build_phase(uvm_phase phase);

  super.build_phase(phase);   

m_drv = apb_driver :: type_id :: create ("m_drv", this);

m_sqr = apb_sequencer :: type_id :: create ("m_sqr", this);

m_mon = apb_monitor :: type_id :: create ("m_mon", this);

endfunction


virtual function void connect_phase (uvm_phase phase);
m_drv.seq_item_port.connect(m_sqr.seq_item_export);

endfunction

endclass
