module regfile (
    regfile_if vif
);
    logic [7:0] mem [16];

    always_ff @(posedge vif.clk, negedge vif.rst_n) begin
        if (vif.rst_n == 0)
            vif.rdata <= '0;

        else begin
            if (vif.wr_en)
                mem[vif.addr] <= vif.wdata;
            else if (vif.rd_en)
                vif.rdata <= mem[vif.addr];
        end
    end

endmodule: regfile
