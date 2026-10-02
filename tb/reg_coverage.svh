class reg_coverage extends uvm_subscriber #(reg_transaction);
    `uvm_component_utils(reg_coverage)

    reg_transaction tr;

    covergroup cg_reg_transaction;
        coverpoint tr.addr;
        coverpoint tr.wr_en;
        coverpoint tr.rd_en;
    endgroup: cg_reg_transaction

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_reg_transaction = new();
    endfunction

    virtual function void write(reg_transaction t);
        this.tr = t;
        cg_reg_transaction.sample();
    endfunction: write

endclass: reg_coverage
