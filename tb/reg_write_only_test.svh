class reg_write_only_test extends reg_test;
    `uvm_component_utils(reg_write_only_test)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        reg_write_only_sequence m_seq = reg_write_only_sequence::type_id::create("m_seq");

        phase.raise_objection(this);
        m_seq.start(m_top_env.m_agent.m_sequencer);
        phase.drop_objection(this);
    endtask: run_phase

endclass: reg_write_only_test
