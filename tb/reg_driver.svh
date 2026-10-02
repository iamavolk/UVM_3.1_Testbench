class reg_driver extends uvm_driver #(reg_transaction);
    `uvm_component_utils(reg_driver)

    virtual regfile_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //      'virtual' keyword is optional here, since paren's
    //      build_phase() is virtual, and so child's override remains virtual
    //      however, for self-documenting and intent,
    //      having 'virtual' is still nice
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if ( !uvm_config_db#(virtual regfile_if)::get(this, "", "vif", vif) )
            `uvm_fatal(this.get_type_name(), "Couldn't get handle")
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        reg_transaction tr;

        forever begin
            this.seq_item_port.get_next_item(tr);

            @(posedge vif.clk) begin
                vif.wr_en <= tr.wr_en;
                vif.rd_en <= tr.rd_en;
                vif.addr  <= tr.addr;
                vif.wdata <= tr.wdata;
            end

            @(posedge vif.clk) begin
                vif.wr_en <= 0;
                vif.rd_en <= 0;
            end

            if (tr.rd_en) begin
                @(posedge vif.clk)
                        tr.rdata = vif.rdata;
            end

            this.seq_item_port.item_done();
        end
    endtask: run_phase


endclass: reg_driver
