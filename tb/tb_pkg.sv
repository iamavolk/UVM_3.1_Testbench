`include "uvm_macros.svh"

package tb_pkg;
    import uvm_pkg::*;
    `include "suppress_uvm_noise.svh"
    `include "reg_transaction.svh"
    `include "reg_driver.svh"
    `include "reg_monitor.svh"
    `include "reg_coverage.svh"
    `include "reg_sequencer.svh"
    `include "reg_sequence.svh"
    `include "reg_write_only_sequence.svh"
    `include "reg_agent.svh"
    `include "reg_scoreboard.svh"
    `include "reg_env.svh"
    `include "reg_test.svh"
    `include "reg_write_only_test.svh"
endpackage: tb_pkg
