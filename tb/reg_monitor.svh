class reg_monitor extends uvm_monitor;
    `uvm_component_utils(reg_monitor)

    // members
    uvm_analysis_port #(reg_transaction) mon_analysis_port;
    //      'virtual' on members means roughly 'reference to handle'
    //      very roughly, in C++ it would be regfile_if* vif (but still not
    //      quite)
    virtual regfile_if vif;
    int unsigned tr_counter;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_analysis_port = new("mon_analysis_port", this);
        tr_counter = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if ( !uvm_config_db #(virtual regfile_if)::get(this, "", "vif", vif) )
            `uvm_error(this.get_type_name(), "Couldn't get a handle to vif")
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        reg_transaction tr;

        forever begin
            @(posedge vif.clk) begin

                if (vif.wr_en) begin: write_enable_first
                    tr = reg_transaction::type_id::create("tr", this);
                    tr.wr_en = 1;
                    tr.addr = vif.addr;
                    tr.wdata = vif.wdata;
                    ++this.tr_counter;
                    `uvm_info(this.get_type_name(),
                              $sformatf("captured write, tr# %0d", tr_counter),
                              UVM_LOW)
                    mon_analysis_port.write(tr);
                end: write_enable_first

                else if (vif.rd_en) begin: read_enable_second
                    tr = reg_transaction::type_id::create("tr", this);
                    tr.rd_en = 1;
                    tr.addr = vif.addr;

                    @(posedge vif.clk) begin
                        tr.rdata = vif.rdata;
                        ++this.tr_counter;
                        `uvm_info(this.get_type_name(),
                                  $sformatf("captured read, tr# %0d", tr_counter),
                                  UVM_LOW)
                        mon_analysis_port.write(tr);
                    end

                end: read_enable_second
            end
        end

    endtask: run_phase

endclass: reg_monitor
