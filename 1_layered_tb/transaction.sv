class transaction;

rand bit[31:0]pwdata;
rand bit[31:0]paddr;
rand bit pwrite;



bit[31:0]prdata;   //observed from DUT
bit psel;
bit penable;
bit pready;


constraint c0 {
        pwdata inside {[0:100]};
        
        }

constraint c1 {
        paddr inside {[0:255]};
        
        }

function new();

endfunction


task run(string name);

$display ("[%s]: paddr: %0d, pwdata: %0d, pwrite: %0d, time: %0t", name,paddr,pwdata,pwrite, $time );

endtask 

endclass  


