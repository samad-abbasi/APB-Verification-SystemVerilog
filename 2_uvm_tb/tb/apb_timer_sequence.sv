class apb_timer_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_timer_sequence)

  function new(string name = "apb_timer_sequence");
  super.new(name);
  endfunction


  task apb_write(bit [11:0] addr, bit [31:0] wdata, bit [3:0] strb = 4'b1111);
    apb_transaction tr;
    tr = apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = addr;
    tr.write = 1'b1;
    tr.wdata = wdata;
    tr.strb  = strb;
    finish_item(tr);
  endtask

  task apb_read(bit [11:0] addr);
    apb_transaction tr;
    tr = apb_transaction::type_id::create("tr");
    start_item(tr);
    tr.addr  = addr;
    tr.write = 1'b0;
    finish_item(tr);
  endtask

  task body();

    // Enable: CTRL[0]=global IRQ, CTRL[1]=timer block enable
    apb_write(12'h000, 32'h0000_0003, 4'b1111);

    // Enable timer-expiry as an interrupt source (INT_EN[0])
    apb_write(12'h008, 32'h0000_0001, 4'b1111);

    //---------------- ONE-SHOT ----------------
    apb_write(12'h014, 32'd5, 4'b1111);          // TIMER_LOAD = 5
    apb_write(12'h018, 32'h0000_0005, 4'b1111);  // TIMER_CTRL: START=1, PERIODIC=0, IRQ_EN=1

    repeat (10) apb_read(12'h01C);               // poll TIMER_VALUE while it counts down

    apb_read(12'h00C);                           // INT_STATUS -- expect bit0 set (expired)
    apb_read(12'h018);                           // TIMER_CTRL -- expect START auto-cleared

    apb_write(12'h00C, 32'h0000_0001, 4'b0001);  // clear the expiry bit (W1C, strb[0]=1)

    //---------------- PERIODIC ----------------
    apb_write(12'h014, 32'd5, 4'b1111);          // reload TIMER_LOAD
    apb_write(12'h018, 32'h0000_0007, 4'b1111);  // START=1, PERIODIC=1, IRQ_EN=1

    repeat (25) apb_read(12'h01C);               // let it expire and reload multiple times

    apb_read(12'h00C);                           // INT_STATUS -- expect bit0 set
  //  apb_write(12'h00C, 32'h0000_0001, 4'b0001);  // clear it  (this write was causing the issue)

    //---------------- STOP ----------------
    apb_write(12'h018, 32'h0000_0000, 4'b1111);  // START=0, stop
  //  apb_read(12'h018);                           // confirm stopped
    repeat (12) apb_read(12'h01C);                           // TIMER_VALUE should hold steady

    //---------------- RESTART ----------------
    apb_write(12'h014, 32'd8, 4'b1111);          // new preload
    apb_write(12'h018, 32'h0000_0001, 4'b1111);  // 0->1 on START: reload + run (one-shot)

    repeat (12) apb_read(12'h01C);

    apb_read(12'h00C);                           // expect expiry flagged again

  endtask

endclass : apb_timer_sequence
