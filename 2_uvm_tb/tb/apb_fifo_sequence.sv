
class apb_fifo_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_fifo_sequence)

  function new(string name = "apb_fifo_sequence");
    super.new(name);
  endfunction


  task fifo_push(bit [31:0] data);
   apb_transaction tr;
    tr = apb_transaction::type_id::create("tr");
    start_item(tr);
     tr.addr  = 12'h020;
     tr.write = 1'b1;
     tr.wdata = data;
    tr.strb  = 4'b1111;
    finish_item(tr);
  endtask
 
 task fifo_pop();
   apb_transaction tr;
   tr = apb_transaction::type_id::create("tr");
   start_item(tr);
    tr.addr  = 12'h020;
   tr.write = 1'b0;
    tr.wdata = 32'h0;
   tr.strb  = 4'b0000;
    finish_item(tr);
  endtask
  
  task fifo_read_status();
    apb_transaction tr;
    tr = apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = 12'h024;   
    tr.write = 1'b0;
    finish_item(tr);
  endtask

  
  
task body();
 
 
 // CTRL[2] =1, Bit 2: FIFO enable
apb_transaction tr;

tr = apb_transaction::type_id::create("ctrl_tr");

start_item(tr);

tr.addr  = 12'h000;
tr.write = 1'b1;
tr.wdata = 32'h0000_0004;
tr.strb  = 4'b1111;

finish_item(tr);
 fifo_read_status();    // expect empty=1, full=0, level=0
 ////////////////fifo starts
 fifo_push(32'h1111_1111);
 fifo_push(32'h2222_2222);
 fifo_push(32'h3333_3333);

 fifo_pop();
 fifo_pop();
fifo_read_status();    // expect level=1, empty=0, full=0
    //FILL FIFO
 repeat (7) begin
  fifo_push($urandom());
  end

 //DRAIN FIFO
 repeat (8) begin
 fifo_pop();
  end
 fifo_read_status();   // expect full=1, empty=0, level=8

 //UNDERFLOW
  fifo_pop();


  //OVERFLOW
   repeat (8) begin
  fifo_push($urandom());
   end   
  fifo_push(32'hDEAD_BEEF);
  endtask
  
 

endclass : apb_fifo_sequence
  





  
  
  
  
  
  
  
  
