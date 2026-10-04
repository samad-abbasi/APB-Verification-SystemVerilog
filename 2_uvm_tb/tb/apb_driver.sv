class apb_driver extends uvm_driver #(apb_transaction);
`uvm_component_utils(apb_driver)


function new(string name ="apb_driver", uvm_component parent=null);
super.new(name,parent);
endfunction


virtual apb_if vif;
//////////////////////////////////////////////////////
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);

if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
`uvm_fatal("[apb_driver]","uvm_config_db get is failed in driver");
endfunction
////////////////////////////////////////////////////////

 virtual task run_phase(uvm_phase phase);
    apb_transaction tr;
    
    
    
    if( vif.PRESETn ==0) begin
    vif.PRESETn = 1'b0;
    vif.PSEL    = 1'b0;
    vif.PENABLE = 1'b0;
    vif.PWRITE  = 1'b0;
    vif.PADDR   = '0;
    vif.PWDATA  = '0;
    vif.PSTRB   = 4'hF;
    end
    
  //  vif.PRESETn = 1'b0;
  
  
 // #10;
    wait (vif.PRESETn == 1'b1);
  //  vif.PRESETn = 1'b1;
    forever begin
      seq_item_port.get_next_item(tr);
      `uvm_info("apb_driver",$sformatf("------transaction is coming ========================================\n tr=%p \n==========================================",tr),UVM_HIGH);

      // Setup phase
      @(posedge vif.PCLK);
      vif.PSEL    <= 1'b1;
      vif.PENABLE <= 1'b0;
      vif.PADDR   <= tr.addr;
      vif.PWRITE  <= tr.write;
      vif.PWDATA  <= tr.wdata;
      vif.PSTRB   <= tr.strb;

      // Access phase
      @(posedge vif.PCLK);
      vif.PENABLE <= 1'b1;

      // Wait for PREADY
      //waitng for PREADy
       `uvm_info("apb_driver","waiting for PReady ",UVM_HIGH);
       @(vif.PREADY)
      `uvm_info("apb_driver","PReady is coing",UVM_HIGH);
      
        @(posedge vif.PCLK);

      tr.rdata  = vif.PRDATA;
      tr.slverr = vif.PSLVERR;

      vif.PSEL    <= 1'b0;
      vif.PENABLE <= 1'b0;

      seq_item_port.item_done();
    end
  endtask
endclass : apb_driver
 




















