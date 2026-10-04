# APB Verification in SystemVerilog: Layered Testbench → UVM with Coverage

Verification of AMBA APB slaves, built up in two stages during my Digital IC Design & Verification training at GIKI (USTP):

1. **Layered testbench:** class-based, constrained-random testbench for a simple APB memory slave
2. **UVM testbench:** a full UVM environment for an APB peripheral (registers, timer, FIFO, RAM, interrupts), with a predictive scoreboard, functional coverage and seven tests

Simulated with Cadence Xcelium (24.09 / 25.03); coverage merged and reported in Cadence IMC.

## Repository layout
```
1_layered_tb/
  apb_slave.sv            DUT: APB slave with a 256 x 32-bit memory
  dut_if.sv               interface: master / slave / monitor clocking blocks + modports
  transaction.sv          randomised APB transfer + constraints
  generator.sv, driver.sv, monitor.sv, scoreboard.sv, environment.sv, test.sv, top.sv
  files.f, xrun.log
2_uvm_tb/
  rtl/                    DUT: apb_peripheral (+ apb_regs, apb_timer, apb_fifo)
  tb/
    apb_if.sv             interface
    apb_transaction.sv    addr, write, wdata, strb (+ rdata, slverr)
    apb_*_sequence.sv     smoke, register, RAM, FIFO, error, timer, random
    apb_sequencer.sv, apb_driver.sv, apb_monitor.sv, apb_agent.sv
    apb_scoreboard.sv     reference model of every register, RAM, FIFO and interrupt
    apb_coverage.sv       uvm_subscriber with the functional covergroup
    apb_environment.sv, apb_test.sv, apb_pkg.sv, apb_top.sv
  results/
    combined_coverage.txt merged coverage summary (all 7 runs)
    merge_cov.tcl         IMC merge script
    xrun_random.log       log of the random regression run
  files.f
```

## APB in short
Each transfer has a **setup** phase (`PSEL=1, PENABLE=0`) and an **access** phase (`PENABLE=1`). The transfer completes on the cycle where `PSEL && PENABLE && PREADY`, and `PSLVERR` reports an error on that cycle.

---

## 1. Layered testbench (`1_layered_tb/`)
```
 generator ──mailbox──► driver (APB master) ──► dut_if ──► apb_slave
                                                  │
 scoreboard ◄──mailbox── monitor ◄────────────────┘
```
- **DUT:** a small FSM, `SETUP` → `W_ENABLE` / `R_ENABLE` → `SETUP`. Memory location `i` resets to `i`.
- **Transaction:** `paddr` (0–255), `pwdata` (0–100) and `pwrite` are randomised.
- **Driver:** acts as the APB master through `master_cb`. It drives the setup phase, then the access phase, and releases the bus once `PREADY` is high.
- **Monitor:** passive, using `monitor_cb`. It records a transfer only when `PSEL && PENABLE && PREADY`.
- **Scoreboard:** a reference copy of the memory. Writes update it and reads are checked against it.

**Result** (`1_layered_tb/xrun.log`): 10 random transfers, 7 writes recorded, 3 reads matched, 0 failures.

---

## 2. UVM testbench (`2_uvm_tb/`)

### DUT: APB peripheral
| Address | Register | Access |
|---|---|---|
| 0x000 | CTRL (global IRQ, timer enable, FIFO enable) | R/W |
| 0x004 | STATUS | R/O |
| 0x008 | INT_EN | R/W |
| 0x00C | INT_STATUS (sticky) | R/W1C |
| 0x010 | SCRATCH | R/W, PSTRB |
| 0x014 / 0x018 / 0x01C | TIMER_LOAD / TIMER_CTRL / TIMER_VALUE | R/W / R/W / R/O |
| 0x020 / 0x024 | FIFO_DATA (push/pop, depth 8) / FIFO_STATUS | R/W / R/O |
| 0x100–0x1FC | 64 x 32-bit RAM | R/W, PSTRB |

The DUT inserts 0–3 random wait states per transfer (LFSR-driven `PREADY`). It also returns `PSLVERR` for several cases:
- writes to read-only registers
- undefined or unaligned addresses
- FIFO access while the FIFO is disabled, or while it is full or empty
- partial-strobe FIFO writes

### Environment
```
 apb_test
 └── apb_environment
     ├── apb_agent
     │   ├── apb_sequencer ◄── sequences (smoke / register / RAM / FIFO / error / timer / random)
     │   ├── apb_driver ──► apb_if ──► apb_peripheral
     │   └── apb_monitor ◄── apb_if
     │          │ mon_analysis_port
     ├── apb_scoreboard ◄──┤ (uvm_analysis_imp)
     └── apb_coverage   ◄──┘ (uvm_subscriber)
```
- **Driver:** runs the APB setup → access sequence and waits through the DUT's random wait states for `PREADY`.
- **Monitor:** publishes every completed transfer on an analysis port. The scoreboard and the coverage collector both subscribe to it.
- **Scoreboard:** a predictive reference model of the whole peripheral:
  - CTRL, INT_EN and SCRATCH
  - INT_STATUS, with write-one-to-clear behaviour
  - timer load, control and expiry
  - an 8-deep FIFO (a SystemVerilog queue), including the full and empty interrupt events
  - the 64-word RAM, with `PSTRB` byte merging
  - the expected `PSLVERR` for every illegal access

  It checks `PRDATA` and `PSLVERR` on every transfer. `TIMER_VALUE` is a free-running counter, so it is not predicted exactly. Instead the scoreboard uses it to infer when the timer expired. The `timer_running` bit of STATUS is masked for the same reason.
- **Coverage (`apb_coverage.sv`):** coverpoints on:
  - read/write
  - every register address, plus the low and high RAM ranges
  - `PSTRB` patterns
  - `PSLVERR`
  - FIFO level, full and empty
  - timer expiry and interrupt sources

  It also has the crosses address×R/W, strobe×R/W and R/W×error.

### Tests (sequences)
| Sequence | What it checks |
|---|---|
| smoke | basic write/read of SCRATCH and RAM |
| register | random R/W of the registers with random `PSTRB`, plus writes to read-only STATUS |
| RAM | 100 random writes with byte strobes, then 100 random reads |
| FIFO | enable FIFO, push/pop, fill to 8, drain, underflow and overflow, FIFO_STATUS checks |
| error | read-only writes, undefined and unaligned addresses, FIFO disabled, illegal `PSTRB`, FIFO underflow and overflow |
| timer | one-shot and periodic modes, expiry interrupt, W1C clear, stop |
| random | constrained-random accesses across the whole legal address map |

### Results
- **Functional coverage, all 7 runs merged in IMC** (`results/combined_coverage.txt`): **87.27%** average, **72 of 81 bins (88.89%)**.
- **Random regression** (`results/xrun_random.log`): the scoreboard reported **49,998 matches and 2 mismatches**. Both mismatches are on INT_STATUS. A similar INT_STATUS mismatch in the timer test was traced to DUT spec §4.4: an interrupt event that arrives in the same cycle as a write-one-to-clear is retained. The DUT is behaving correctly there, but a transaction-level model cannot see that same-cycle timing (see the note at the top of `apb_scoreboard.sv`).

### Run
```bash
cd 2_uvm_tb
xrun -uvm -sv -f files.f -access +rwc -coverage functional -covtest run_random
imc -exec results/merge_cov.tcl      # merge the per-test coverage databases
```

## Author
Abdul Samad Abbasi
