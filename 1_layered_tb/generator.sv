class generator;



mailbox#(transaction)gen2drv;
event ended;
function new(mailbox#(transaction)gen2drv);
this.gen2drv=gen2drv;
endfunction



task run();
int generated_count;
transaction tr;
repeat (10) begin
tr=new();
if(!tr.randomize()) $fatal ("Gen:: trans randomization failed");
gen2drv.put(tr);
generated_count++;
tr.run("GEN");
$display("Total Gen transactions are:%d",generated_count);
end
$display("Total Gen transactions are:%d",generated_count);

-> ended;
endtask
endclass 

/*
module check; 
generator gen1;
mailbox#(transaction)gen2drv;
initial begin 
gen2drv=new();
gen1 = new(gen2drv);
gen1.run();
end 
endmodule
*/

