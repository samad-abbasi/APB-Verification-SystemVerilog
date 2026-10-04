/*
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"
`include "test.sv"
`include "dut_if.sv"
`include "top.sv"

*/


module top;

logic rst_n, clk;

dut_if vif(clk,rst_n);

apb_slave dut(vif);

always #5 clk = ~clk;

test t;
initial begin 

clk =0;
rst_n=0;
#10;
rst_n=1;
t=new(vif);
t.run();
$finish;
end 
endmodule 
  
  
  
  
