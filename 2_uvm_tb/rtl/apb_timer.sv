module apb_timer (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        block_enable,
  input  logic        wr_load,
  input  logic        wr_ctrl,
  input  logic [31:0] wr_data,
  input  logic [3:0]  wr_strb,
  output logic [31:0] load_value,
  output logic [2:0]  ctrl_value,
  output logic [31:0] current_value,
  output logic        running,
  output logic        expiry_pulse
);

  function automatic logic [31:0] apply_strb(
    input logic [31:0] old_v,
    input logic [31:0] new_v,
    input logic [3:0]  strb
  );
    logic [31:0] tmp;
    begin
      tmp = old_v;
      for (int i = 0; i < 4; i++) begin
        if (strb[i]) tmp[i*8 +: 8] = new_v[i*8 +: 8];
      end
      return tmp;
    end
  endfunction

  logic [31:0] load_next, current_next;
  logic [2:0]  ctrl_next;
  logic        expiry_next;
  logic [31:0] merged_ctrl;

  always_comb begin
    load_next    = load_value;
    ctrl_next    = ctrl_value;
    current_next = current_value;
    expiry_next  = 1'b0;
    merged_ctrl  = apply_strb({29'b0, ctrl_value}, wr_data, wr_strb);

    if (wr_load) begin
      load_next = apply_strb(load_value, wr_data, wr_strb);
      if (ctrl_value[0]) current_next = apply_strb(load_value, wr_data, wr_strb);   // provided RTL had !ctrl_value[0] here
    end

    if (wr_ctrl) begin
      ctrl_next = merged_ctrl[2:0];
      // A 0->1 transition on START loads the programmed preload value.
      if (merged_ctrl[0] && !ctrl_value[0]) current_next = load_next;
    end

    // Timer advances only when it was already running before this cycle.
    // This avoids decrementing on the same cycle START is asserted.
    if (block_enable && ctrl_value[0] && !wr_ctrl) begin
      if (current_value > 1) begin
        current_next = current_value - 1'b1;
      end else if (current_value == 1) begin
        current_next = 32'h0000_0000;
        expiry_next  = ctrl_value[2];
        if (ctrl_value[1]) begin
          current_next = load_value;
        end else begin
          ctrl_next[0] = 1'b0;
        end
      end
    end
  end

  assign running = block_enable && ctrl_value[0] && (current_value != 0);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      load_value    <= 32'h0000_0000;
      ctrl_value    <= 3'b000;
      current_value <= 32'h0000_0000;
      expiry_pulse  <= 1'b0;
    end else begin
      load_value    <= load_next;
      ctrl_value    <= ctrl_next;
      current_value <= current_next;
      expiry_pulse  <= expiry_next;
    end
  end

endmodule
