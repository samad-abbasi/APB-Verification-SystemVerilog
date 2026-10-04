class apb_error_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_error_sequence)

  function new(string name = "apb_error_sequence");
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
  
    // Write to read-only registers 
    apb_write(12'h004, 32'hFFFF_FFFF, 4'b1111);  // STATUS     
    apb_write(12'h01C, 32'hFFFF_FFFF, 4'b1111);  // TIMER_VALUE 
    apb_write(12'h024, 32'hFFFF_FFFF, 4'b1111);  // FIFO_STATUS 

 // Undefined address 
 apb_write(12'h030, 32'hDEAD_BEEF, 4'b1111);  
 apb_read (12'h030);                           


 apb_write(12'h101, 32'hDEAD_BEEF, 4'b1111);  // not word-aligned 0x100 SRAM
  apb_read (12'h101);                         
    
  // FIFO access while disabled 
  apb_write(12'h000, 32'h0000_0000, 4'b1111);  // CTRL[2] not enabled for fifo
  apb_write(12'h020, 32'h1234_5678, 4'b1111);  // FIFO_DATA push 
  apb_read (12'h020);                          // FIFO_DATA pop 

 // FIFO write with illegal PSTRB 
 apb_write(12'h000, 32'h0000_0004, 4'b1111);  // CTRL [2] enabled
 apb_write(12'h020, 32'hCAFE_1234, 4'b1010); 

  // FIFO underflow 
  apb_read (12'h020);                          // pop while empty 

  // FIFO overflow 
  repeat (8) 
  apb_write(12'h020, $urandom(), 4'b1111);  
  apb_write(12'h020, 32'hDEAD_BEEF, 4'b1111);        
  endtask
  
  
 

endclass : apb_error_sequence
  





  
  
  
  
  
  
  
  
