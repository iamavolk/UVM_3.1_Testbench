class reg_sequence extends uvm_sequence #(reg_transaction);
    `uvm_object_utils(reg_sequence)

    function new (string name = "reg_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat (5) begin
            this.req = reg_transaction::type_id::create("req");
            this.start_item(req);
            assert(req.randomize())
                else `uvm_fatal(this.get_type_name(), "randomization of the sequence fails")
            this.finish_item(req);
        end
    endtask: body

endclass: reg_sequence
