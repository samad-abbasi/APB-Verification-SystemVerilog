
class apb_random_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_random_sequence)

  function new(string name = "apb_random_sequence");
    super.new(name);
  endfunction

  task body();
    apb_transaction tr;
    int num_transactions=500;

  //  num_transactions = $urandom_range(500, 2000);
 //   `uvm_info("RANDOM_SEQ", $sformatf("Running %0d random transactions", num_transactions), UVM_LOW)

    repeat (num_transactions) begin
      tr = apb_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize())
        `uvm_error("RANDOM_SEQ", "randomize failed")
      finish_item(tr);
    end

  endtask

endclass : apb_random_sequence
  





  
  
  
  
  
  
  
  
