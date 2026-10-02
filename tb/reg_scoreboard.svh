class reg_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(reg_scoreboard)

    uvm_analysis_imp #(reg_transaction, reg_scoreboard) ap_imp;

    bit [7:0] expected_mem [16];
    bit       written [16];

    int unsigned num_mismatches = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase


    virtual function void write(reg_transaction tr);

        if (tr.wr_en) begin: write
            expected_mem[tr.addr] = tr.wdata;
            written[tr.addr] = 1;
        end: write

        else if (tr.rd_en) begin: read

            if (!written[tr.addr]) begin: read_before_write
                `uvm_info(this.get_type_name(),
                          $sformatf("addr=%0d read before any write, skipping check", tr.addr),
                          UVM_LOW)
            end: read_before_write

            else if (tr.rdata != expected_mem[tr.addr]) begin: read_mismatch
                `uvm_error(
                    this.get_type_name(),
                    $sformatf("mismatch at addr=%0d: expected=0x%0h, actual=0x%0h",
                               tr.addr, expected_mem[tr.addr], tr.rdata))
                    ++num_mismatches;
            end: read_mismatch

            else begin: match
                `uvm_info(this.get_type_name(),
                          $sformatf("addr=%0d matched: 0x%0h", tr.addr, tr.rdata),
                          UVM_HIGH)
            end: match

        end: read
    endfunction: write

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(
            this.get_type_name(),
            $sformatf("Total mismatches: %0d", num_mismatches),
            UVM_LOW)
    endfunction: report_phase

endclass: reg_scoreboard
