class test;

virtual dut_if vif;
environment env;
function new(virtual dut_if vif);
this.vif = vif;
env = new(vif);
endfunction


task run();

env.run();
endtask 

endclass