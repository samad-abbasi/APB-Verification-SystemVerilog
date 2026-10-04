
class apb_monitor extends uvm_monitor;

`uvm_component_utils(apb_monitor)



function new(string name ="apb_monitor", uvm_component parent);
super.new(name,parent);
endfunction

virtual apb_if vif;
uvm_analysis_port#(apb_transaction)mon_analysis_port;


//////////////////////////////////////////////////////
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
mon_analysis_port = new("mon_analysis_port", this);
if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
`uvm_fatal("[apb_monitor]","uvm_config_db get is failed in monitor")
endfunction
////////////////////////////////////////////////////////




virtual task run_phase(uvm_phase phase);

apb_transaction tr;
 `uvm_info("apb_monitor","------Monitor run phase-----",UVM_HIGH);
forever begin

@(posedge vif.PCLK);

if (vif.PSEL == 1'b1 && vif.PENABLE == 1'b1 && vif.PREADY == 1'b1) begin
 tr = apb_transaction::type_id::create("tr");
 tr.addr   = vif.PADDR;
 tr.write  = vif.PWRITE;
tr.wdata  = vif.PWDATA;
 tr.strb   = vif.PSTRB;
tr.rdata  = vif.PRDATA;
 tr.slverr = vif.PSLVERR;
 `uvm_info("apb_monitor","Monitor is sending the data",UVM_HIGH);

 mon_analysis_port.write(tr);
 end
 end
endtask

endclass


