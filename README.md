# APB Slave Verification using UVM

A UVM testbench that verifies an **AMBA APB slave** connected to a 64 KB memory.
The testbench checks normal read/write transfers, byte strobes, error responses (`PSLVERR`),
back-to-back transfers, and collects functional and code coverage.

---

## Table of Contents

1. [Overview](#overview)
2. [Design Under Test (DUT)](#design-under-test-dut)
3. [Testbench Architecture](#testbench-architecture)
4. [Tests](#tests)
5. [Functional Coverage](#functional-coverage)
6. [Project Structure](#project-structure)
7. [How to Run](#how-to-run)
8. [Results](#results)
9. [Known Limitations and Future Work](#known-limitations-and-future-work)

---

## Overview

| Item | Details |
|---|---|
| Protocol | AMBA APB (slave side) |
| Methodology | UVM 1.2 |
| Language | SystemVerilog |
| Simulator | Synopsys VCS |
| Coverage | Functional coverage + code coverage (line, condition, toggle) |

---

## Design Under Test (DUT)

Top module: `apb_wrapper`

| Parameter | Default | Meaning |
|---|---|---|
| `ADDR_W` | 32 | Address width |
| `DATA_W` | 64 | Data width |
| `MEM_SIZE_K` | 64 | Memory size in KB |
| `BASE_ADDR` | 0 | Base address of the memory |

The DUT has four blocks:

- **`apb_fsm`**: APB slave state machine (`IDLE` -> `SETUP` -> `ACCESS`). It drives `PREADY`, `PSLVERR` and `PRDATA`. A write is blocked when an error is detected.
- **`generic_mem`**: Memory built from `mem_1024x32` blocks (2 columns x 8 rows for 64-bit data). It supports byte strobes (`PSTRB`) and gives read data with a valid signal after a 2-cycle delay.
- **`mem_1024x32`**: Basic 1024 x 32-bit RAM (synchronous write, asynchronous read).
- **`err_gen`**: Creates the error flags:
  - **Out-of-bounds**: address is outside `BASE_ADDR` to `BASE_ADDR + 64 KB`.
  - **Misaligned**: address is not 8-byte aligned (64-bit bus).

When an error happens, `PSLVERR` is asserted with `PREADY` and the write is **not** done.

---

## Testbench Architecture

```
                         +---------------------------------------------+
                         |                  apb_env                    |
  +-----------+          |  +-------------------------------------+    |
  | Sequences |--------->|  |             apb_agent               |    |
  +-----------+          |  |  +-----------+     +-----------+    |    |
                         |  |  | sequencer |---->|  driver   |----+----+--> APB interface --> DUT
                         |  |  +-----------+     +-----------+    |    |
                         |  |                    +-----------+    |    |
                         |  |                    |  monitor  |<---+----+--- APB interface <-- DUT
                         |  |                    +-----+-----+    |    |
                         |  +--------------------------|----------+    |
                         |                  +----------+----------+    |
                         |                  v                     v    |
                         |          +--------------+     +-------------+
                         |          |  scoreboard  |     |  coverage   |
                         |          +--------------+     +-------------+
                         +---------------------------------------------+
```

| Component | File | Job |
|---|---|---|
| Interface | `apb_interface.sv` | APB signals between TB and DUT |
| Transaction | `apb_transaction.sv` | Address, data, strobe, direction, response |
| Sequencer | `apb_sequencer.sv` | Passes items from sequences to the driver |
| Driver | `apb_driver.sv` | Drives APB transfers with one idle cycle between them |
| Back-to-back driver | `apb_b2b_driver.sv` | Starts the next transfer right after the previous one (no idle cycle) |
| Monitor | `apb_monitor.sv` | Watches the bus and sends completed transfers to the scoreboard and coverage |
| Scoreboard | `apb_scoreboard.sv` | Reference memory model, checks read data and `PSLVERR` |
| Coverage | `apb_coverage.sv` | Functional coverage collector |
| Agent / Env | `apb_agent.sv`, `apb_env.sv` | Connects all components |

---

## Tests

| Test | Sequence | What it checks |
|---|---|---|
| `apb_random_test` | `apb_base_seq` | 100 random aligned full-strobe writes |
| `apb_wr_rd_test` | `apb_wr_rd_seq` | Write then read back, partial strobes on fixed addresses, read-only phase |
| `apb_err_test` | `apb_err_seq` | **Error injection**: out-of-bounds, misaligned, and both together. Also boundary addresses such as `0x0`, `0xFFF8`, `0x1_0000`, `0xFFFF_FFFF` |
| `apb_err_alias_test` | `apb_err_alias_seq` | **Error-write aliasing**: an invalid write must not change memory. The test writes good data to address `A`, then writes different data through addresses that map to the same memory word (for example `A + 0x1_0000`, `A + 4`). Then it reads `A` back and checks the data is unchanged |
| `apb_b2b_test` | `apb_b2b_seq` | **Back-to-back transfers**: burst writes, burst reads, write-after-write, read-after-write, and mixed valid and invalid accesses without idle cycles |

---

## Functional Coverage

Implemented in `apb_coverage.sv` with two covergroups.

**`cg` (transfer coverage)**

- Direction: read / write
- Address class: valid, out-of-bounds, misaligned, out-of-bounds + misaligned
- Boundary addresses: first word, last word, first out-of-bounds address, maximum address
- Memory row (all 8 rows)
- Write strobe patterns: none, full, lower half, upper half, each single byte lane
- Observed `PSLVERR`
- Transitions: read-read, read-write, write-read, write-write
- Crosses: direction x address class, direction x error, direction x strobe

**`cg_b2b` (back-to-back coverage)**

- Next transfer started after an idle gap, or back-to-back
- Crossed with the previous direction and the previous error status

---

## Project Structure

```
.
├── rtl/
│   ├── design.sv            # apb_wrapper (top)
│   ├── apb_fsm.sv
│   ├── err_gen.sv
│   ├── generic_mem.sv
│   └── mem_1024x32.sv
├── tb/
│   ├── apb_interface.sv
│   ├── apb_top.sv           # tb_top + apb_pkg (includes all UVM files)
│   ├── apb_transaction.sv
│   ├── apb_sequencer.sv
│   ├── apb_driver.sv
│   ├── apb_b2b_driver.sv
│   ├── apb_monitor.sv
│   ├── apb_scoreboard.sv
│   ├── apb_coverage.sv
│   ├── apb_agent.sv
│   ├── apb_env.sv
│   ├── apb_base_seq.sv
│   ├── apb_wr_rd_test.sv    # apb_wr_rd_seq
│   ├── apb_err_seq.sv
│   ├── apb_err_alias_seq.sv
│   ├── apb_b2b_seq.sv
│   ├── apb_base_test.sv
│   └── apb_test.sv          # all test classes
└── sim/
    ├── Makefile
    ├── build.flist
    └── out/                 # build and result folders (created by the flow)
```

---

## How to Run

**Requirements:** Synopsys VCS with UVM 1.2, and `urg` / `dve` for coverage reports.

Run all commands from the `sim/` folder. Make sure the `out/` folder exists:

```bash
mkdir -p out
```

**Run one test** (compile + simulate):

```bash
make wr_rd       # apb_wr_rd_test
make random      # apb_random_test
make err         # apb_err_test
make alias       # apb_err_alias_test
make b2b         # apb_b2b_test
```

You can also run any test by name:

```bash
make run TEST=apb_err_test
```

**Run all tests and merge coverage:**

```bash
make all_tests
```

**Other targets:**

| Command | Action |
|---|---|
| `make compile` | Compile only |
| `make sim` | Simulate only (uses `TEST`) |
| `make gui` | Open waveform in DVE |
| `make cov` | Merge coverage and create the URG report in `out/coverage_report` |
| `make clean` | Remove the build of the current `TEST` |
| `make allclean` | Remove everything in `out/` |

**See functional coverage:**

```bash
grep -H COV_SUMMARY out/build_*/log_build_*.log
firefox out/coverage_report/dashboard.html
```

Each test prints `PASS` or `FAIL` at the end of its log.

---

## Results

All 5 tests **PASS**, with no `PSLVERR` mismatches in any test.

| Test | Transfers (Write / Read) | `PSLVERR` check (pass / fail) | Functional cov `cg` | Functional cov `cg_b2b` | Result |
|---|---|---|---|---|---|
| `apb_random_test` | 100 (100 / 0) | 100 / 0 | 31.67 % | 40.00 % | PASS |
| `apb_wr_rd_test` | 230 (100 / 130) | 230 / 0 | 51.25 % | 55.00 % | PASS |
| `apb_err_test` | 150 (69 / 81) | 150 / 0 | 76.67 % | 70.00 % | PASS |
| `apb_err_alias_test` | 440 (160 / 280) | 440 / 0 | 74.17 % | 70.00 % | PASS |
| `apb_b2b_test` | 212 (114 / 98) | 212 / 0 | 74.17 % | 90.00 % | PASS |

The percentages above are for each test alone. Different tests hit different bins, so the merged coverage of all tests is higher than any single test.

**Code coverage (merged, from URG):**

| Scope | Score | Line | Condition | Toggle |
|---|---|---|---|---|
| `tb_top` | 99.47 | 100.00 | 98.60 | 99.81 |
| `dut` (`apb_wrapper`) | 99.49 | 100.00 | 98.60 | 99.85 |

**Main observations**

- The **aliasing test passes**: invalid writes (out-of-bounds and misaligned) do not change the memory.
- The **error tests pass**: `PSLVERR` is correct for out-of-bounds, misaligned, and combined cases.
- The **back-to-back test reaches 90 %** on `cg_b2b`, which shows the transfers really start without idle cycles. Other tests use the normal driver, so they show idle gaps.
- The DUT reaches **100 % line coverage**.

---

## Known Limitations and Future Work

- No SystemVerilog Assertions (SVA) yet. The `ASSERT` column in the code coverage report is empty.
- No reset-in-the-middle-of-a-transfer test.
- Functional coverage is not closed yet. Planned: more directed sequences for the missing bins (strobe lanes, boundary addresses, memory rows).
- The master side does not add random wait states or `PSTRB` corner cases beyond the current sequences.
- The scoreboard read-data counters need cleanup so the pass/fail numbers are exact.
