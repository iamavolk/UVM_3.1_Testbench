module top;

    typedef enum bit [2:0] {
        NO_OP  = 3'b000,
        ADD_OP = 3'b001,
        AND_OP = 3'b010,
        XOR_OP = 3'b011,
        MUL_OP = 3'b100,
        RST_OP = 3'b111
    } operation_t;

    logic clk, rst_n;

    logic         start, done;
    logic [2:0]   op;
    logic [15:0]  result;

    byte unsigned a, b;
    operation_t op_set;

    tinyalu DUT(
        .clk     (clk),
        .rst_n   (rst_n),
        .start_i (start),
        .a_i     (a),
        .b_i     (b),
        .op_i    (op),
        .done_o  (done),
        .result_o(result)
    );

    ///////////////////////////////////////////////////////////////////////////
    //  Coverage
    covergroup operation_coverage;
        option.at_least = 1;    //  1 is default
        op_coverpoint: coverpoint op_set {
            // bins single_cycle[] = { [ADD_OP:XOR_OP], RST_OP, NO_OP };
            // bins multi_cycle = { MUL_OP };

            //
            //          as of Verilator 5.055, value range is still unsupported, but
            //          manual expansion works just fine
            //
            bins op_to_rst[]    = ( [ADD_OP:MUL_OP] => RST_OP );
            // bins rst_to_op[]    = ( RST_OP => [ADD_OP:MUL_OP] );
            // bins sngl_to_mul[]  = ( [ADD_OP:XOR_OP] => MUL_OP );
            // bins mul_to_sngl[]  = ( MUL_OP => [ADD_OP:XOR_OP] );
            // bins op_to_rst[] = (
            //     ADD_OP => RST_OP,
            //     AND_OP => RST_OP,
            //     XOR_OP => RST_OP,
            //     MUL_OP => RST_OP
            // );

            // bins add_to_rst = (ADD_OP => RST_OP);
            // bins and_to_rst = (AND_OP => RST_OP);
            // bins xor_to_rst = (XOR_OP => RST_OP);
            // bins mul_to_rst = (MUL_OP => RST_OP);
            //
            // bins rst_to_op[] =
            // (
            //     RST_OP => ADD_OP,
            //     RST_OP => AND_OP,
            //     RST_OP => XOR_OP,
            //     RST_OP => MUL_OP
            // );
            //
            // bins sngl_to_mul[] =
            // (
            //     ADD_OP => MUL_OP,
            //     AND_OP => MUL_OP,
            //     XOR_OP => MUL_OP
            // );
            //
            // bins mul_to_sngl[] =
            // (
            //     MUL_OP => ADD_OP,
            //     MUL_OP => AND_OP,
            //     MUL_OP => XOR_OP
            // );

            //          also, this may work
            // bins two_ops[]      = ( [ADD_OP:MUL_OP] [* 2]);
            // bins manymult[]     = ( MUL_OP [* 3:5] );
            // bins two_ops[] =
            // (
            //     ADD_OP => ADD_OP,
            //     ADD_OP => AND_OP,
            //     ADD_OP => XOR_OP,
            //     ADD_OP => MUL_OP,
            //
            //     AND_OP => ADD_OP,
            //     AND_OP => AND_OP,
            //     AND_OP => XOR_OP,
            //     AND_OP => MUL_OP,
            //
            //     XOR_OP => ADD_OP,
            //     XOR_OP => AND_OP,
            //     XOR_OP => XOR_OP,
            //     XOR_OP => MUL_OP,
            //
            //     MUL_OP => ADD_OP,
            //     MUL_OP => AND_OP,
            //     MUL_OP => XOR_OP,
            //     MUL_OP => MUL_OP
            // );
            //

            // bins manymult_3 = (MUL_OP => MUL_OP => MUL_OP);
            // bins manymult_4 = (MUL_OP => MUL_OP => MUL_OP => MUL_OP);
            // bins manymult_5 = (MUL_OP => MUL_OP => MUL_OP => MUL_OP => MUL_OP);

            //
            //      _verilator fails to expand this into individual bins,
            //      which results in inadequate handling of the bins
            // bins manymult[] =
            // (
            //     MUL_OP => MUL_OP => MUL_OP,
            //     MUL_OP => MUL_OP => MUL_OP => MUL_OP,
            //     MUL_OP => MUL_OP => MUL_OP => MUL_OP => MUL_OP
            // );
        }
    endgroup: operation_coverage


    initial begin: clock
        clk = 0;
        forever #10 clk = ~clk;
    end: clock


    operation_coverage op_cov;
    initial begin: coverage
        op_cov = new();
        forever begin
            @(negedge clk);
            op_cov.sample();
        end
    end: coverage

    ///////////////////////////////////////////////////////////////////////////
    //  ad-hoc data randomization
    function automatic operation_t get_op();
        int unsigned op_choice;
        op_choice = $urandom_range(0, 7);

        unique case (op_choice)
            3'b000, 3'b101: return NO_OP;
            3'b001: return ADD_OP;
            3'b010: return AND_OP;
            3'b011: return XOR_OP;
            3'b100: return MUL_OP;
            3'b110, 3'b111: return RST_OP;
        endcase
    endfunction: get_op

    function automatic byte unsigned get_data();
        bit [1:0] zero_ones;
        zero_ones = 2'($urandom()); // explicit static cast makes LSP happy

        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hff;
        else
            return 8'($urandom()); // explicit static cast again
    endfunction: get_data


    ///////////////////////////////////////////////////////////////////////////
    //  ad-hoc scoreboard
    always @(posedge done) begin: scoreboard
        logic [15:0] predicted_result;
        #1;

        case (op_set)
            ADD_OP: predicted_result = a + b;
            AND_OP: predicted_result = a & b;
            XOR_OP: predicted_result = a ^ b;
            MUL_OP: predicted_result = a * b;
        endcase

        if ((op_set != NO_OP) && (op_set != RST_OP))
            if (predicted_result != result)
                $error ("FAILED: a: %0h  b: %0h  op: %s result: %0h",
                        a, b, op_set.name(), result);

    end: scoreboard

    ///////////////////////////////////////////////////////////////////////////
    // ad-hoc test
    initial begin: test
        rst_n = 0;
        start = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;

        repeat (1000) begin
            @(negedge clk);
            op_set = get_op();
            op = op_set;
            a = get_data();
            b = get_data();
            start = 1;

            case (op_set)
                NO_OP: begin
                    @(posedge clk);
                    start = 0;
                end
                RST_OP: begin
                    rst_n = 0;
                    start = 0;
                    @(negedge clk);
                    rst_n = 1;
                end
                default: begin
                    wait(done);
                    start = 0;
                end
            endcase
        end
        $finish();

    end: test

endmodule: top
