class reg_agent extends uvm_agent;
    `uvm_component_utils(reg_agent)

    reg_driver    m_driver;
    reg_monitor   m_monitor;
    reg_sequencer m_sequencer;
    reg_coverage  m_coverage;

    bit enable_coverage = 1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //
        //      checks whether the agent is active;
        //      active or passive is configured in
        //
        //      uvm_config_db#(uvm_active_passive_enum)::set(
        //          this,
        //          "agent",
        //          "is_active",
        //          UVM_PASSIVE
        //      );
        //
        //     with active/passive determined by:
        //
        //     typedef enum {
        //          UVM_PASSIVE,
        //          UVM_ACTIVE
        //     } uvm_active_passive_enum;
        //
        if (this.get_is_active()) begin
            m_sequencer = reg_sequencer::type_id::create("m_sequencer", this);
            m_driver    = reg_driver::type_id::create("m_driver", this);
        end

        if (this.enable_coverage)
            m_coverage = reg_coverage::type_id::create("m_coverage", this);

        m_monitor  = reg_monitor::type_id::create("m_monitor", this);

    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if(this.get_is_active())
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);

        if (this.enable_coverage)
            m_monitor.mon_analysis_port.connect(m_coverage.analysis_export);
    endfunction: connect_phase

endclass: reg_agent
