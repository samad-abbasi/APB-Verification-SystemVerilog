//`include "uvm_macros.svh"
import uvm_pkg::*;
import apb_pkg::*;

module top;

    logic clk;
    logic rst_n;

    apb_if vif(.PCLK(clk));

apb_peripheral dut (
    .PCLK(clk), .PRESETn (vif.PRESETn), .PADDR   (vif.PADDR),
    .PSEL(vif.PSEL),.PENABLE (vif.PENABLE),.PWRITE  (vif.PWRITE),
    .PWDATA(vif.PWDATA),.PSTRB   (vif.PSTRB),.PRDATA  (vif.PRDATA),
    .PREADY(vif.PREADY),.PSLVERR (vif.PSLVERR),
    .IRQ(vif.IRQ)
  );




    // Clock
    always #5 clk = ~clk;

    // Reset
   initial begin
       clk = 0;
     //   vif.PRESETn = 0;

   //     #5;
 //        vif.PRESETn = 1;

  
    vif.PRESETn = 1'b0;
    vif.PSEL    = 1'b0;
    vif.PENABLE = 1'b0;
    vif.PWRITE  = 1'b0;
    vif.PADDR   = '0;
    vif.PWDATA  = '0;
    vif.PSTRB   = 4'hF;
    repeat (4) @(posedge vif.PCLK);
    vif.PRESETn = 1'b1;
 end
 
 
    // Virtual interface
    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);

        run_test("apb_test");
    end

endmodule
