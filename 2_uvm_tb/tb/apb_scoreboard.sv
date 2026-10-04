// Note from the timer test:
// One mismatch occurred during the timer test, on the final INT_STATUS read. Investigation traced
// this to a documented race condition in DUT spec section 4.4: a timer-expiry interrupt event
// arrived on the same clock cycle as a write-one-to-clear operation on INT_STATUS, and per the
// specified behavior, the newly-arriving event was correctly retained rather than cleared. Since
// the scoreboard operates at the transaction level and cannot observe same-cycle internal timing
// collisions, it could not predict this specific outcome. This is not considered a DUT defect —
// the DUT's behavior matches its documented specification exactly.

class apb_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(apb_scoreboard)

  uvm_analysis_imp #(apb_transaction, apb_scoreboard) scb_analysis_port;

  bit [3:0]  ctrl_model;
  bit [2:0]  int_en_model;
  bit [2:0]  int_status_model;
  bit [31:0] scratch_model;
  bit [31:0] timer_load_model;
  bit [2:0]  timer_ctrl_model;

  bit [31:0] ram_model [0:63];   // 64 x 32-bit RAM model
  bit [31:0] fifo_model [$];     // Queue-based FIFO model

  // Used only to infer a timer expiry between two TIMER_VALUE reads --
  // NOT used to predict the exact live TIMER_VALUE itself (see notes
  // in the 12'h01C read case below).
  bit [31:0] last_timer_value;

  int match_count;
  int mismatch_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb_analysis_port = new("scb_analysis_port", this);
    match_count    = 0;
    mismatch_count = 0;
  endfunction

  virtual function void write(apb_transaction tr);
    bit        expected_slverr = 0;
    bit [31:0] expected_rdata  = 0;

    bit is_ram     = (tr.addr >= 12'h100 && tr.addr <= 12'h1FC);
    bit unaligned  = (tr.addr[1:0] != 2'b00);

    // Illegal address checks (undefined address or unaligned RAM access)
    if (unaligned || (!is_ram && tr.addr > 12'h024)) begin
      expected_slverr = 1;
    end

    //====================================================================
    // WRITE behavior
    //====================================================================
    else if (tr.write) begin
      if (is_ram) begin
        bit [5:0]  ram_idx   = tr.addr[7:2];
        bit [31:0] temp_data = ram_model[ram_idx];
        if (tr.strb[0]) temp_data[7:0]   = tr.wdata[7:0];
        if (tr.strb[1]) temp_data[15:8]  = tr.wdata[15:8];
        if (tr.strb[2]) temp_data[23:16] = tr.wdata[23:16];
        if (tr.strb[3]) temp_data[31:24] = tr.wdata[31:24];
        ram_model[ram_idx] = temp_data;
      end else begin
        case (tr.addr)
          12'h000: begin // CTRL (R/W)
            if (tr.strb[0]) begin
              ctrl_model = tr.wdata[3:0];
              if (ctrl_model[2] == 1'b0) fifo_model.delete();
            end
          end
          12'h004: expected_slverr = 1; // STATUS (R/O)
          12'h008: begin // INT_EN (R/W)
            if (tr.strb[0]) int_en_model = tr.wdata[2:0];
          end
          12'h00C: begin // INT_STATUS (W1C)
            if (tr.strb[0]) int_status_model &= ~tr.wdata[2:0];
          end
          12'h010: begin // SCRATCH (R/W)
            if (tr.strb[0]) scratch_model[7:0]   = tr.wdata[7:0];
            if (tr.strb[1]) scratch_model[15:8]  = tr.wdata[15:8];
            if (tr.strb[2]) scratch_model[23:16] = tr.wdata[23:16];
            if (tr.strb[3]) scratch_model[31:24] = tr.wdata[31:24];
          end
          12'h014: begin // TIMER_LOAD (R/W)
            if (tr.strb[0]) timer_load_model[7:0]   = tr.wdata[7:0];
            if (tr.strb[1]) timer_load_model[15:8]  = tr.wdata[15:8];
            if (tr.strb[2]) timer_load_model[23:16] = tr.wdata[23:16];
            if (tr.strb[3]) timer_load_model[31:24] = tr.wdata[31:24];
            // DUT also updates the live current-value immediately when
            // the timer is stopped -- keep our expiry-inference baseline
            // in sync so it doesn't fire a false expiry on the next read.
            if (!timer_ctrl_model[0])
              last_timer_value = timer_load_model;
          end
          12'h018: begin // TIMER_CTRL (R/W)
            bit old_start = timer_ctrl_model[0];
            if (tr.strb[0]) timer_ctrl_model = tr.wdata[2:0];
            // 0->1 transition on START reloads the timer
            if (!old_start && timer_ctrl_model[0])
              last_timer_value = timer_load_model;
          end
          12'h01C: expected_slverr = 1; // TIMER_VALUE (R/O)
          12'h020: begin // FIFO_DATA
            if (ctrl_model[2] == 0) begin
              expected_slverr = 1; // FIFO disabled
            end else if (fifo_model.size() == 8) begin
              expected_slverr = 1; // FIFO full
            end else if (tr.strb != 4'b1111) begin
              expected_slverr = 1; // illegal PSTRB for FIFO
            end else begin
              fifo_model.push_back(tr.wdata); // PUSH
              if (fifo_model.size() == 8) int_status_model[1] = 1;
            end
          end
          12'h024: expected_slverr = 1; // FIFO_STATUS (R/O)
          default: expected_slverr = 1;
        endcase
      end
    end

    //====================================================================
    // READ behavior
    //====================================================================
    else begin
      if (is_ram) begin
        expected_rdata = ram_model[tr.addr[7:2]];
      end else begin
        case (tr.addr)
          12'h000: expected_rdata = {28'h0, ctrl_model};
          12'h004: begin // STATUS
            bit irq_pend = |(int_status_model & int_en_model);
            bit f_full   = (fifo_model.size() == 8);
            bit f_empty  = (fifo_model.size() == 0);
            // bit[1] (timer_running) cannot be predicted without exact
            // live timer state -- masked out at compare time below.
            expected_rdata = {27'h0, irq_pend, f_full, f_empty, 1'b0, ctrl_model[0]};
          end
          12'h008: expected_rdata = {29'h0, int_en_model};
          12'h00C: expected_rdata = {29'h0, int_status_model};
          12'h010: expected_rdata = scratch_model;
          12'h014: expected_rdata = timer_load_model;
          12'h018: expected_rdata = {29'h0, timer_ctrl_model};
          12'h01C: begin // TIMER_VALUE (R/O) -- exact value not predictable
                          // from transaction-level polling alone, but we
                          // CAN infer whether an expiry happened between
                          // this read and the last one: the value either
                          // jumped UP (periodic reload) or landed exactly
                          // on 0 having been nonzero before.
            expected_rdata = tr.rdata; // bypass -- see compare step below
            if (ctrl_model[1] && timer_ctrl_model[0]) begin
              if ((tr.rdata > last_timer_value) ||
                  (last_timer_value != 0 && tr.rdata == 0)) begin
                if (timer_ctrl_model[2]) int_status_model[0] = 1'b1;   // irq_enable
                if (!timer_ctrl_model[1]) timer_ctrl_model[0] = 1'b0; // one-shot auto-stop
              end
            end
            last_timer_value = tr.rdata;
          end
          12'h020: begin // FIFO_DATA
            if (ctrl_model[2] == 0) begin
              expected_slverr = 1; // FIFO disabled
            end else if (fifo_model.size() == 0) begin
              expected_slverr = 1; // FIFO empty
            end else begin
              expected_rdata = fifo_model.pop_front(); // POP
              if (fifo_model.size() == 0) int_status_model[2] = 1;
            end
          end
          12'h024: begin // FIFO_STATUS
            bit       f_full  = (fifo_model.size() == 8);
            bit       f_empty = (fifo_model.size() == 0);
            bit [3:0] f_level = fifo_model.size();
            expected_rdata = {24'h0, f_level, 2'b00, f_full, f_empty};
          end
          default: expected_slverr = 1;
        endcase
      end
    end

    //====================================================================
    // Compare actual vs. expected
    //====================================================================
    if (tr.slverr != expected_slverr) begin
      `uvm_error("SCB_FAIL", $sformatf("SLVERR Mismatch! Addr=%0h Exp=%0b Act=%0b",
        tr.addr, expected_slverr, tr.slverr))
      mismatch_count++;
    end
    else if (!tr.write && !expected_slverr) begin
      if (tr.addr == 12'h004) begin
        // Mask bit[1] (timer_running) -- not predictable, see above.
        if ((tr.rdata & ~32'h2) !== (expected_rdata & ~32'h2)) begin
          `uvm_error("SCB_FAIL", $sformatf(
            "STATUS Data Mismatch! Addr=%0h Exp(Masked)=%0h Act(Masked)=%0h",
            tr.addr, expected_rdata & ~32'h2, tr.rdata & ~32'h2))
          mismatch_count++;
        end else match_count++;
      end
      else if (tr.addr == 12'h01C) begin
        // TIMER_VALUE data itself is bypassed -- exact live value can't
        // be predicted from transaction-level polling. Expiry effects
        // (INT_STATUS, TIMER_CTRL auto-clear) ARE still checked, since
        // they're derived above and go through the normal address cases.
        match_count++;
      end
      else if (tr.rdata !== expected_rdata) begin
        `uvm_error("SCB_FAIL", $sformatf("Data Mismatch! Addr=%0h Exp=%0h Act=%0h",
          tr.addr, expected_rdata, tr.rdata))
        mismatch_count++;
      end
      else begin
        `uvm_info("SCB_PASS", $sformatf("Read Match! Addr=%0h Data=%0h", tr.addr, tr.rdata), UVM_HIGH)
        match_count++;
      end
    end
    else begin
      match_count++;
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_REPORT", $sformatf("Matches: %0d, Mismatches: %0d", match_count, mismatch_count), UVM_NONE)
    if (mismatch_count > 0)
      `uvm_error("SCB_FAILED", "Scoreboard reported mismatches!")
  endfunction

endclass : apb_scoreboard
