
class apb_sequence extends uvm_sequence #(apb_transaction);
`uvm_object_utils(apb_sequence)

function new(string name = "apb_sequence");
super.new(name);
endfunction



apb_transaction tr;
virtual task body();
repeat(20) begin
tr = apb_transaction::type_id::create("tr");
start_item(tr);
assert(tr.randomize());



finish_item(tr);

end
endtask
endclass : apb_sequence



  
  
  
  
  
  
  
  
