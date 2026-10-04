
class apb_coverage extends uvm_subscriber #(apb_transaction);

  `uvm_component_utils(apb_coverage)

  apb_transaction tr;


  // Covergroup -- one instance, sampled on every observed transaction.

  covergroup cg;
    option.per_instance = 1;

    // Read vs. write
    cp_rw: coverpoint tr.write {
      bins write = {1};
      bins read  = {0};
    }

    // Register address selection (+ RAM address regions)
    cp_addr: coverpoint tr.addr {
      bins ctrl        = {12'h000};
       bins status       = {12'h004};
        bins int_en       = {12'h008};
       bins int_status   = {12'h00C};
       bins scratch      = {12'h010};
      bins timer_load   = {12'h014};
       bins timer_ctrl   = {12'h018};
      bins timer_value  = {12'h01C};
       bins fifo_data    = {12'h020};
       bins fifo_status  = {12'h024};
      bins ram_low      = {[12'h100:12'h17C]};   
      bins ram_high     = {[12'h180:12'h1FC]};   
      bins illegal      = default;               // undefined addresses
    }

    // PSTRB values
    cp_strb: coverpoint tr.strb {
      bins full   = {4'b1111};
      bins none   = {4'b0000};
      bins byte0  = {4'b0001};
      bins byte1  = {4'b0010};
      bins byte2  = {4'b0100};
      bins byte3  = {4'b1000};
      bins others = default;
    }

    // PSLVERR assertion
    cp_slverr: coverpoint tr.slverr {
      bins ok    = {0};
      bins error = {1};
    }

    // FIFO empty/full/level behavior (sampled only on FIFO_STATUS reads)
    cp_fifo_level: coverpoint tr.rdata[7:4] iff (tr.addr == 12'h024 && !tr.write) {
      bins level[] = {[0:8]};
    }
    cp_fifo_empty: coverpoint tr.rdata[0] iff (tr.addr == 12'h024 && !tr.write) {
      bins is_empty     = {1};
      bins is_not_empty = {0};
    }
    cp_fifo_full: coverpoint tr.rdata[1] iff (tr.addr == 12'h024 && !tr.write) {
      bins is_full     = {1};
      bins is_not_full = {0};
    }

    // Timer expiration (sampled on INT_STATUS reads)
    cp_timer_expired: coverpoint tr.rdata[0] iff (tr.addr == 12'h00C && !tr.write) {
      bins expired     = {1};
      bins not_expired = {0};
    }

    // Interrupt sources (which INT_STATUS bits are set)
    cp_int_source: coverpoint tr.rdata[2:0] iff (tr.addr == 12'h00C && !tr.write) {
      bins none             = {3'b000};
      bins timer_only        = {3'b001};
      bins fifo_full_only    = {3'b010};
      bins fifo_empty_only   = {3'b100};
      bins multiple_sources  = default;
    }

  
    cx_addr_rw:    cross cp_addr, cp_rw;
    cx_strb_write: cross cp_strb, cp_rw;
    cx_op_slverr:  cross cp_rw, cp_slverr;

  endgroup

function new(string name, uvm_component parent);
  super.new(name, parent);
  cg = new();
  cg.set_inst_name($sformatf("cg_%s", name)); 
endfunction


  // write(): called automatically for every transaction the monitor

  virtual function void write(apb_transaction t);
    tr = t;
    cg.sample();
  endfunction


  // report_phase: print final coverage percentage.

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT",
      $sformatf("Functional coverage: %0.2f%%", cg.get_coverage()),
      UVM_LOW)
  endfunction

endclass : apb_coverage
