class reg_write_only_sequence extends reg_sequence;
    `uvm_object_utils(reg_write_only_sequence)

    function new(string name= "reg_write_only_seq");
        super.new();
    endfunction

    virtual task body();
        repeat (5) begin
            this.req = reg_transaction::type_id::create("req");
            this.start_item(req);
            assert(req.randomize() with { req.rd_en == 0; }) // generate only writes
                else `uvm_fatal(this.get_type_name(), "randomization of the sequence fails")
            this.finish_item(req);
        end
    endtask: body

endclass: reg_write_only_sequence
