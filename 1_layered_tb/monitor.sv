class monitor;

mailbox #(transaction)mon2scb;
virtual dut_if vif;
function new(mailbox #(transaction)mon2scb,virtual dut_if vif);
this.mon2scb = mon2scb;
this.vif=vif;


endfunction


task run();
transaction tr;

forever begin
@(vif.monitor_cb)
if(vif.monitor_cb.psel && vif.monitor_cb.penable && vif.monitor_cb.pready) begin
tr = new();

tr.paddr=vif.monitor_cb.paddr;
tr.pwdata=vif.monitor_cb.pwdata;
tr.prdata=vif.monitor_cb.prdata;

tr.pwrite=vif.monitor_cb.pwrite;
tr.psel=vif.monitor_cb.psel;
tr.penable=vif.monitor_cb.penable;

mon2scb.put(tr);
tr.run("Monitor");
end
end


endtask

endclass
