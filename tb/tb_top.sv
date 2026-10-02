module tb_top;
    import tb_pkg::*;

    bit clk;
    always #10 clk = ~clk;

    regfile_if reg_if0 (clk);
    regfile    dut0    (reg_if0);

    initial begin
        ///////////////////////////////////////////////////
        //     Suppresses UVM_RELNOTES and other noise
        ///////////////////////////////////////////////////
        static suppress_uvm_noise catcher = new();
        uvm_pkg::uvm_report_cb::add(null, catcher);
        ///////////////////////////////////////////////////

        uvm_pkg::uvm_config_db #(virtual regfile_if)::set(null, "uvm_test_top.*", "vif", reg_if0);
        uvm_pkg::run_test();
    end
endmodule: tb_top
