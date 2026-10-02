class reg_test extends uvm_test;
    `uvm_component_utils(reg_test)

    reg_env m_top_env;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_top_env = reg_env::type_id::create("m_top_env", this);
    endfunction: build_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction: end_of_elaboration_phase

    virtual task run_phase(uvm_phase phase);
        reg_sequence m_seq = reg_sequence::type_id::create("m_seq");

        phase.raise_objection(this);
        m_seq.start(m_top_env.m_agent.m_sequencer);
        phase.drop_objection(this);
    endtask: run_phase

endclass: reg_test
