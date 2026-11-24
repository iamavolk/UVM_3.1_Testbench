interface fifo_ext_hshake_if
#(
    parameter int DWIDTH = 8,
    parameter int AWIDTH = 4
)(
    input logic clk
);
    timeunit 1ns/1ps;

    logic rst_n, w_en, r_en;
    logic full, empty;

    logic [DWIDTH-1:0]  d_in, d_out;

    clocking cb @(posedge clk);
        output d_in;
        output r_en;
        output w_en;

        input  d_out;
        input  full;
        input  empty;
    endclocking: cb

    modport DUT (
        input  clk,
        //  from TB
        input  w_en, r_en, rst_n,
        input  d_in,

        //  into TB
        output d_out,
        output full, empty
    );

    modport TEST (
       clocking cb,
       input    clk,
       output   rst_n
    );

endinterface: fifo_ext_hshake_if
