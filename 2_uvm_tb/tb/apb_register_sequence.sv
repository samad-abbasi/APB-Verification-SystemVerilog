
class apb_register_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_register_sequence)

  function new(string name = "apb_register_sequence");
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
    bit        write;

    repeat (40) begin

      // Randomly select one of the NORMAL R/W registers
      case ($urandom_range(0,5))
    //dut spec sheet says that STATUS , TIMER_VALUE, FIFO_STATUS are read-only
        0: addr = 12'h000;   // CTRL
        1: addr = 12'h008;   // INT_EN
        2: addr = 12'h01C;   // INT_STATUS slave error will come too
        3: addr = 12'h010;   // SCRATCH
        4: addr = 12'h014;   // TIMER_LOAD
        5: addr = 12'h004;    //STATUS reg for checing SLVERR ata
      endcase


    
      write = $urandom_range(0,1);
      wdata = $urandom();
      strb = $urandom_range(1,15);

      if (write) begin
        apb_write(addr, wdata, strb);
        apb_read(addr);
      end
    
     // else begin
      //  apb_read(addr);
     // end

    end
endtask

endclass : apb_register_sequence
  





  
  
  
  
  
  
  
  
