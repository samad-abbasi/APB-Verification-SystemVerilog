class environment;
generator gen;
driver drv;
monitor mon;
scoreboard scb;

virtual dut_if vif;
mailbox #(transaction) gen2drv;
mailbox #(transaction) mon2scb;



function new (virtual dut_if vif);
this.vif = vif;
gen2drv = new();
mon2scb = new();

  gen=new(gen2drv);
drv=new(gen2drv,vif);
mon=new(mon2scb,vif);
scb=new(mon2scb);
endfunction



task run();
drv.reset();

fork 
gen.run();
drv.run();
mon.run();
scb.run();
join_none

  wait(gen.ended.triggered)
#500;

endtask

endclass
