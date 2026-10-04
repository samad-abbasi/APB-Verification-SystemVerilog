
class apb_smoke_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_smoke_sequence)

  function new(string name = "apb_smoke_sequence");
    super.new(name);
  endfunction


  task apb_write(bit [11:0] addr, bit [31:0] wdata, bit [3:0] strb = 4'b1111);
    apb_transaction tr;
    tr = apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = addr;
    tr.write = 1'b1;
    tr.wdata = wdata;
    tr.strb  = strb;
    finish_item(tr);
  endtask

  task apb_read(bit [11:0] addr);
    apb_transaction tr;
    tr = apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = addr;
    tr.write = 1'b0;
    finish_item(tr);
  endtask

  task body();
  `uvm_info("apb_smoke_test","----inside body task-----",UVM_LOW)
    // SCRATCH register (0x010)
    apb_write(12'h010, 32'hDEAD_BEEF);
    apb_read (12'h010);

    // Scratch RAM location 0 (0x100)
    apb_write(12'h100, 32'hCAFE_1234);
    apb_read (12'h100);
  endtask

endclass : apb_smoke_sequence
  





  
  
  
  
  
  
  
  
