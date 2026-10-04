

class driver;

mailbox#(transaction)gen2drv;
virtual dut_if vif;

function new(mailbox#(transaction)gen2drv,virtual dut_if vif);
this.gen2drv=gen2drv;
this.vif=vif;

endfunction


task reset();
vif.psel=0;
vif.penable=0;
vif.pwrite=0;

endtask


task run();
transaction tr;
vif.master_cb.psel<=0;
vif.master_cb.penable<=0;

forever begin

//initial phase
gen2drv.get(tr);
tr.run("Driver");

//setup phase
@(vif.master_cb)
vif.master_cb.psel<=1;
vif.master_cb.penable<=0;
vif.master_cb.pwdata<=tr.pwdata;
vif.master_cb.paddr<=tr.paddr;
vif.master_cb.pwrite<=tr.pwrite;

//access
@(vif.master_cb)
vif.master_cb.penable<=1;

if(!tr.pwrite) 
tr.prdata = vif.master_cb.prdata;   //reading from slave if write is low 

@(vif.master_cb)
if(vif.master_cb.pready) begin
vif.master_cb.psel <=0;
vif.master_cb.penable<=0;
end

end
endtask



endclass
