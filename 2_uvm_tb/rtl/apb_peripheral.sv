module apb_peripheral (
  input  logic        PCLK,
  input  logic        PRESETn,
  input  logic [11:0] PADDR,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [31:0] PWDATA,
  input  logic [3:0]  PSTRB,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR,
  output logic        IRQ
);

  localparam logic [11:0] A_CTRL        = 12'h000;
  localparam logic [11:0] A_STATUS      = 12'h004;
  localparam logic [11:0] A_INT_EN      = 12'h008;
  localparam logic [11:0] A_INT_STATUS  = 12'h00C;
  localparam logic [11:0] A_SCRATCH     = 12'h010;
  localparam logic [11:0] A_TIMER_LOAD  = 12'h014;
  localparam logic [11:0] A_TIMER_CTRL  = 12'h018;
  localparam logic [11:0] A_TIMER_VALUE = 12'h01C;
  localparam logic [11:0] A_FIFO_DATA   = 12'h020;
  localparam logic [11:0] A_FIFO_STATUS = 12'h024;

  logic [31:0] ram [0:63];

  logic [3:0]  ctrl;
  logic [2:0]  int_en, int_status;
  logic [31:0] scratch;

  logic [31:0] timer_load, timer_current;
  logic [2:0]  timer_ctrl;
  logic        timer_running, timer_expiry_pulse;

  logic [31:0] fifo_rdata;
  logic        fifo_empty, fifo_full;
  logic [3:0]  fifo_level;
  logic        fifo_push, fifo_pop;

  logic [2:0] event_set;
  logic       prev_fifo_empty, prev_fifo_full;

  logic wr_ctrl, wr_int_en, wr_int_status, wr_scratch;
  logic wr_timer_load, wr_timer_ctrl;

  logic [1:0] wait_count;
  logic [7:0] lfsr;
  logic       transfer_done;
  logic       access_error;
  logic       valid_read, valid_write;
  logic       ram_sel;
  logic [5:0] ram_index;

  assign ram_sel   = (PADDR >= 12'h100) && (PADDR <= 12'h1FC) && (PADDR[1:0] == 2'b00);
  assign ram_index = PADDR[7:2];

  // A small synthesizable LFSR selects 0..3 APB wait states per transfer.
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      lfsr       <= 8'hA5;
      wait_count <= 2'd0;
    end else begin
      lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
      if (PSEL && !PENABLE)
        wait_count <= lfsr[1:0];
      else if (PSEL && PENABLE && wait_count != 0)
        wait_count <= wait_count - 1'b1;
    end
  end

  assign PREADY        = PSEL && PENABLE && (wait_count == 0);
  assign transfer_done = PSEL && PENABLE && PREADY;

  always_comb begin
    valid_read  = 1'b1;
    valid_write = 1'b1;

    unique case (PADDR)
      A_CTRL:        ;
      A_STATUS:      valid_write = 1'b0;
      A_INT_EN:      ;
      A_INT_STATUS:  ;
      A_SCRATCH:     ;
      A_TIMER_LOAD:  ;
      A_TIMER_CTRL:  ;
      A_TIMER_VALUE: valid_write = 1'b0;
      A_FIFO_DATA: begin
        if (!ctrl[2]) begin
          valid_read  = 1'b0;
          valid_write = 1'b0;
        end else begin
          if (fifo_empty) valid_read  = 1'b0;
          if (fifo_full)  valid_write = 1'b0;
          if (PSTRB != 4'b1111) valid_write = 1'b0;
        end
      end
      A_FIFO_STATUS: valid_write = 1'b0;
      default: begin
        if (!ram_sel) begin
          valid_read  = 1'b0;
          valid_write = 1'b0;
        end
      end
    endcase
  end

  assign access_error = PWRITE ? !valid_write : !valid_read;
  assign PSLVERR      = transfer_done && access_error;

  always_comb begin
    PRDATA = 32'h0000_0000;
    unique case (PADDR)
      A_CTRL:        PRDATA = {28'b0, ctrl};
      A_STATUS:      PRDATA = {27'b0, (|(int_status & int_en)), fifo_full, fifo_empty, timer_running, ctrl[0]};
      A_INT_EN:      PRDATA = {29'b0, int_en};
      A_INT_STATUS:  PRDATA = {29'b0, int_status};
      A_SCRATCH:     PRDATA = scratch;
      A_TIMER_LOAD:  PRDATA = timer_load;
      A_TIMER_CTRL:  PRDATA = {29'b0, timer_ctrl};
      A_TIMER_VALUE: PRDATA = timer_current;
      A_FIFO_DATA:   PRDATA = fifo_rdata;
      A_FIFO_STATUS: PRDATA = {24'b0, fifo_level, 2'b00, fifo_full, fifo_empty};
      default:       PRDATA = ram_sel ? ram[ram_index] : 32'h0000_0000;
    endcase
  end

  assign wr_ctrl       = transfer_done && PWRITE && !access_error && (PADDR == A_CTRL);
  assign wr_int_en     = transfer_done && PWRITE && !access_error && (PADDR == A_INT_EN);
  assign wr_int_status = transfer_done && PWRITE && !access_error && (PADDR == A_INT_STATUS);
  assign wr_scratch    = transfer_done && PWRITE && !access_error && (PADDR == A_SCRATCH);
  assign wr_timer_load = transfer_done && PWRITE && !access_error && (PADDR == A_TIMER_LOAD);
  assign wr_timer_ctrl = transfer_done && PWRITE && !access_error && (PADDR == A_TIMER_CTRL);

  assign fifo_push = transfer_done && PWRITE  && !access_error && (PADDR == A_FIFO_DATA);
  assign fifo_pop  = transfer_done && !PWRITE && !access_error && (PADDR == A_FIFO_DATA);

  // Scratch RAM write path.
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      for (int i = 0; i < 64; i++) ram[i] <= 32'h0000_0000;
    end else if (transfer_done && PWRITE && !access_error && ram_sel) begin
      for (int b = 0; b < 4; b++)
        if (PSTRB[b]) ram[ram_index][b*8 +: 8] <= PWDATA[b*8 +: 8];
    end
  end

  apb_fifo #(.WIDTH(32), .DEPTH(8)) u_fifo (
    .clk       (PCLK),
    .rst_n     (PRESETn),
    .clear     (!ctrl[2]),
    .push      (fifo_push),
    .pop       (fifo_pop),
    .push_data (PWDATA),
    .pop_data  (fifo_rdata),
    .empty     (fifo_empty),
    .full      (fifo_full),
    .level     (fifo_level)
  );

  apb_timer u_timer (
    .clk           (PCLK),
    .rst_n         (PRESETn),
    .block_enable  (ctrl[1]),
    .wr_load       (wr_timer_load),
    .wr_ctrl       (wr_timer_ctrl),
    .wr_data       (PWDATA),
    .wr_strb       (PSTRB),
    .load_value    (timer_load),
    .ctrl_value    (timer_ctrl),
    .current_value (timer_current),
    .running       (timer_running),
    .expiry_pulse  (timer_expiry_pulse)
  );

  // FIFO interrupt sources are edge events: entering FULL or EMPTY.
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      prev_fifo_empty <= 1'b1;
      prev_fifo_full  <= 1'b0;
    end else begin
      prev_fifo_empty <= fifo_empty;
      prev_fifo_full  <= fifo_full;
    end
  end

  assign event_set[0] = timer_expiry_pulse;
  assign event_set[1] = fifo_full  && !prev_fifo_full;
  assign event_set[2] = fifo_empty && !prev_fifo_empty;

  apb_regs u_regs (
    .clk           (PCLK),
    .rst_n         (PRESETn),
    .wr_ctrl       (wr_ctrl),
    .wr_int_en     (wr_int_en),
    .wr_int_status (wr_int_status),
    .wr_scratch    (wr_scratch),
    .wr_data       (PWDATA),
    .wr_strb       (PSTRB),
    .event_set     (event_set),
    .ctrl          (ctrl),
    .int_en        (int_en),
    .int_status    (int_status),
    .scratch       (scratch)
  );

  // CTRL[0] acts as a global interrupt-output enable.
  assign IRQ = ctrl[0] && (|(int_status & int_en));

endmodule
