# UVM 3.1 Testbench

For now, this repo contains a small SystemVerilog/UVM testbench for a sync write/sync read
16-entry register file. Elements:

- IEEE-1800 3.1 UVM framework
- selecting tests with `+UVM_TESTNAME` (via Makefile)

## Testbench structure

The DUT exposes a 4-bit address, 8-bit write/read data, and separate read/write
enables. A transaction is either a read or a write:

```text
reg_transaction
        |
        v
reg_sequence -> reg_sequencer -> reg_driver -> regfile
                                             |
reg_monitor <- regfile_if ------------------+
      |
      +--> reg_coverage
      |
      +--> reg_scoreboard
```

Constrained randomized tests:
- `reg_sequence`
- `reg_write_only_sequence`


## Requirements

- Verilator 5.05x (tested on `5.055 devel rev v5.054-325-g464643f7c`)
- C++ toolchain (tested on `GNU GCC 16.2.1`);
- `z3` solver (tested on `4.16.0`);
- [uvm-verilator](https://github.com/chipsalliance/uvm-verilator) at `$(HOME)/uvm-verilator`

## How to run

The file list contains `tb/tb_top.sv`, so select `tb_top` as the Verilator
top module. Select the UVM test with `TEST_NAME`:

```sh
make run TOP=tb_top TEST_NAME=reg_test SEED=12345
```

The `run` target:

1. compiles the design and UVM package;
2. builds `.obj_dir/Vtb_top`;
3. passes `+UVM_TESTNAME=$(TEST_NAME)` to the executable;
4. runs the selected UVM test.


## Coverage

WIP


## UVM report output

This testbench makes use of a custom message suppressor `suppress_uvm_noise`.
Its primary job is to catch startup messages such as UVM RELNOTES and NO-DPI warnings
It does not suppress actual testbench errors.
