
class apb_environment extends uvm_env;

`uvm_component_utils(apb_environment)

apb_agent      e_agent;
apb_scoreboard e_scb;

apb_coverage   e_cov;    

function new(string name = "apb_environment", uvm_component parent=null);
super.new(name, parent);
endfunction


virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
e_agent = apb_agent :: type_id :: create ("e_agent", this);
e_scb = apb_scoreboard :: type_id :: create ("e_scb", this);

e_cov   = apb_coverage :: type_id :: create ("e_cov", this); 
endfunction



virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
e_agent.m_mon.mon_analysis_port.connect(e_scb.scb_analysis_port);

e_agent.m_mon.mon_analysis_port.connect(e_cov.analysis_export);
endfunction


endclass



