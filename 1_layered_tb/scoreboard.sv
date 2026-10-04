class scoreboard;
  mailbox #(transaction) mon2scb;
  logic [31:0] m[0:255];
  logic [31:0] expected;

  function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
    for (int i = 0; i < 256; i++)
      m[i] = i;
  endfunction

  task run();
    transaction tr;
    forever begin
      mon2scb.get(tr);

      if (tr.pwrite == 1) begin
        m[tr.paddr] = tr.pwdata;
        $display("write tr succesful: addr: %0d , data: %0d", tr.paddr, tr.pwdata);
      end
      else begin
        expected = m[tr.paddr];
        if (expected == tr.prdata) begin
          $display("read tr successful: addr: %0d , expected data: %0d , actual data: %0d", 
                    tr.paddr, expected, tr.prdata);
        end
        else begin
          $display("FAIL: addr: %0d , expected: %0d , actual: %0d", 
                    tr.paddr, expected, tr.prdata);
        end
      end
    end
  endtask
endclass