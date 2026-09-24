class Transaction;
    rand bit [31:0] data;
    rand bit  [2:0] dst;
endclass: Transaction



covergroup CovDst with function sample(Transaction tr);
    cov_data: coverpoint tr.data;
    cov_dst:  coverpoint tr.dst;
    cross cov_data, cov_dst;
endgroup: CovDst



module coverage_top;
    Transaction tr;
    CovDst cov = new();

    initial begin
        repeat (32) begin
            tr = new();
            assert(tr.randomize());
            cov.sample(tr);
        end
    end

endmodule: coverage_top
