class suppress_uvm_noise extends uvm_report_catcher;

    function new(string name="");
        super.new(name);
    endfunction

    virtual function action_e catch();
        string id = get_id();

        if (id == "UVM/COMP/NAMECHECK"  ||
            id == "NO_VISIT_CHECK"      ||
            id == "UVM/RELNOTES"        ||
            id == "NO_DPI_TSTNAME"      ||
            id == "NO_DPI_USED")
            return CAUGHT;

        return THROW;
    endfunction: catch

endclass: suppress_uvm_noise
