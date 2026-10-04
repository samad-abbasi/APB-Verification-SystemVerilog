
class apb_test extends uvm_test;

`uvm_component_utils(apb_test)

apb_environment env;


function new(string name = "apb_test", uvm_component parent=null);
super.new(name, parent);
endfunction


virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
env = apb_environment :: type_id :: create ("env", this);
endfunction


virtual task run_phase(uvm_phase phase);

apb_smoke_sequence smk_seq;
apb_register_sequence reg_seq;
apb_ram_sequence ram_seq;
apb_fifo_sequence fifo_seq;
apb_error_sequence error_seq;
apb_random_sequence rad_seq;
apb_timer_sequence timer_seq;



//smk_seq = apb_smoke_sequence :: type_id :: create ("smk_seq", this);
//reg_seq=apb_register_sequence :: type_id:: create ("reg_seq", this);
//ram_seq=apb_ram_sequence :: type_id:: create ("ram_seq", this);
//fifo_seq=apb_fifo_sequence :: type_id:: create ("fifo_seq", this);

//error_seq=apb_error_sequence :: type_id:: create ("error_seq", this);
rad_seq=apb_random_sequence :: type_id:: create ("rad_seq", this);
//timer_seq = apb_timer_sequence :: type_id :: create ("timer_seq", this);

phase.raise_objection(this, "Start apb_smoke_sequence");
`uvm_info("apb_test","-----Sequene Starting-----",UVM_HIGH)
rad_seq.start(env.e_agent.m_sqr);

phase.drop_objection(this, "End apb_smoke_sequence");
endtask

endclass



