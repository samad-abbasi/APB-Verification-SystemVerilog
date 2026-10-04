module apb_regs (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        wr_ctrl,
  input  logic        wr_int_en,
  input  logic        wr_int_status,
  input  logic        wr_scratch,
  input  logic [31:0] wr_data,
  input  logic [3:0]  wr_strb,
  input  logic [2:0]  event_set,
  output logic [3:0]  ctrl,
  output logic [2:0]  int_en,
  output logic [2:0]  int_status,
  output logic [31:0] scratch
);

  function automatic logic [31:0] apply_strb(
    input logic [31:0] old_v,
    input logic [31:0] new_v,
    input logic [3:0]  strb
  );
    logic [31:0] tmp;
    begin
      tmp = old_v;
      for (int i = 0; i < 4; i++)
        if (strb[i]) tmp[i*8 +: 8] = new_v[i*8 +: 8];
      return tmp;
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ctrl       <= 4'b0000;
      int_en     <= 3'b000;
      int_status <= 3'b000;
      scratch    <= 32'h0000_0000;
    end else begin
      if (wr_ctrl) begin
        logic [31:0] merged;
        merged = apply_strb({28'b0, ctrl}, wr_data, wr_strb);
        ctrl   <= merged[3:0];
      end

      if (wr_int_en) begin
        logic [31:0] merged;
        merged = apply_strb({29'b0, int_en}, wr_data, wr_strb);
        int_en <= merged[2:0];
      end

      if (wr_scratch)
        scratch <= apply_strb(scratch, wr_data, wr_strb);

      // W1C has priority first, then newly arriving events are set.
      if (wr_int_status && wr_strb[0])
        int_status <= (int_status & ~wr_data[2:0]) | event_set;
      else
        int_status <= int_status | event_set;
    end
  end

endmodule
