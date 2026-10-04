class apb_ram_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_ram_sequence)

  function new(string name = "apb_ram_sequence");
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
  
    bit [11:0] addr;
    bit [31:0] wdata;
    bit [3:0]  strb;
  
  //100 random writes
  repeat (100) begin
  
      addr = 12'h100 + ($urandom_range(0,63) * 4);
      wdata = $urandom();
      strb = $urandom_range(1,15);
      apb_write(addr, wdata, strb);
    end
  
    //100 random reads
  repeat (100) begin
      addr = 12'h100 + ($urandom_range(0,63) * 4);
      apb_read(addr);
    end

  endtask
  
 

endclass : apb_ram_sequence
  





  
  
  
  
  
  
  
  
