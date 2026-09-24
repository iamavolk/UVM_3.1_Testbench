typedef int int_queue_t[$];
typedef int intmap_t[int];
typedef int unsigned uint_t;

typedef struct { int value; bit flag; } value_flag_t;

class Packet;
    rand bit [7:0]  addr;
    rand bit [15:0] data;
    rand bit        write;

    constraint test_constr {
        if (!write) { data == 0; }
        addr[1:0] == 2'b00;
    }

    function Packet clone();
        Packet p = new();

        p.addr = this.addr;
        p.data = this.data;
        p.write = this.write;

        return p;
    endfunction: clone

    function bit same_as(input Packet other);
        return  (this.addr == other.addr) &&
                (this.write == other.write) &&
                (this.data == other.data);
    endfunction: same_as
endclass: Packet

class Generator;
    mailbox #(Packet) gen_mb;
    uint_t num_packets;

    function new(
        input uint_t packets = 20,
        input mailbox #(Packet) mb
    );
        this.num_packets = packets;
        this.gen_mb = mb;
    endfunction

    task give_packets();
        Packet p;
        for (uint_t i = 0; i < this.num_packets; ++i) begin
            p = new();
            if(!p.randomize())
                $fatal("error during randomization");
            gen_mb.put(p);
        end

    endtask: give_packets

endclass: Generator

class Driver;
    mailbox #(Packet) from_gen_mb;
    mailbox #(Packet) to_scb_mb;
    uint_t num_packets;

    function new(
        input mailbox #(Packet) from_gen,
        input mailbox #(Packet) to_scb,
        input uint_t packet_count
    );
        this.from_gen_mb = from_gen;
        this.to_scb_mb = to_scb;
        this.num_packets = packet_count;
    endfunction

    task run();
        Packet incoming_packet;
        Packet outgoing_packet;

        for (uint_t i = 0; i < this.num_packets; ++i) begin
            from_gen_mb.get(incoming_packet);
            outgoing_packet = incoming_packet.clone();
            to_scb_mb.put(outgoing_packet);
        end
    endtask: run
endclass: Driver

class Scoreboard;
    mailbox #(Packet) from_gen_mb;
    mailbox #(Packet) from_drv_mb;
    uint_t num_packets;

    function new(
        input mailbox #(Packet) from_gen,
        input mailbox #(Packet) from_drv,
        input uint_t packet_count
    );
        this.from_gen_mb = from_gen;
        this.from_drv_mb = from_drv;
        this.num_packets = packet_count;

    endfunction

    task recv();
        Packet drv_p;
        Packet gen_p;

        for (uint_t i = 0; i < num_packets; ++i) begin
            from_gen_mb.get(gen_p);
            from_drv_mb.get(drv_p);
        end

    endtask

endclass: Scoreboard

//      Requirements:
//      - Generator creates 20 randomized Packet objects.
//      - It sends them through:
//      mailbox #(Packet)
//      - Driver receives each packet and creates a clone.
//      - Driver sends the clone to a second mailbox.
//      - Scoreboard receives original/clone pairs and compares them.
//      - Report:
//      - number received;
//      - number matched;
//      - number mismatched.
//      - Run generator, driver, and scoreboard concurrently using fork...join.
//      No DUT is needed. This exercises classes, mailboxes, cloning, comparison, and concurrent processes.

module test_top;
endmodule: test_top
