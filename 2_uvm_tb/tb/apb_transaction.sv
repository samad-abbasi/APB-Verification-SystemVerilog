class apb_transaction extends uvm_sequence_item;
`uvm_object_utils(apb_transaction)


function new(string name = "apb_transaction");
super.new(name);
endfunction

rand bit [11:0] addr;
rand bit write;
rand bit [31:0] wdata;
rand bit [3:0] strb;

//used by driver 

bit [31:0] rdata;
bit slverr;

  constraint c1 {
   (addr inside {12'h000, 12'h004, 12'h008, 12'h00C, 12'h010,
                        12'h014, 12'h018, 12'h01C, 12'h020, 12'h024} ||
          (addr >= 12'h100 && addr <= 12'h1FC && addr[1:0] == 2'b00));
  }


endclass



