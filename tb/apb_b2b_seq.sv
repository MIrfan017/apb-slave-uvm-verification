class apb_b2b_seq extends apb_base_seq;
    `uvm_object_utils(apb_b2b_seq)

    int unsigned num_burst = 16;
    int unsigned num_raw   = 20;
    int unsigned num_mix   = 80;

    function new(string name = "apb_b2b_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] a;
        bit [31:0] base;
        bit [31:0] pool[8];

        `uvm_info(get_type_name(),"Back-to-Back Sequence Started :", UVM_LOW);

        // ---------------- 1. burst writes, consecutive words ----------------
        base = $urandom_range(32'd0, 32'd60000) & 32'h0000_FFF8;
        for(int i = 0; i < num_burst; i++) begin
            a = base + (i * 8);
            `uvm_do_with(req,{
                write == 1'b1;
                addr  == local::a;
                strb  == 8'hFF;
            })
        end

        // ---------------- 2. burst reads, same words ----------------
        for(int i = 0; i < num_burst; i++) begin
            a = base + (i * 8);
            `uvm_do_with(req,{
                write == 1'b0;
                addr  == local::a;
            })
        end

        // ---------------- 3. RAW and WAW on the same address ----------------
        repeat(num_raw) begin
            a = $urandom_range(32'd0, 32'd65535) & 32'h0000_FFF8;
            `uvm_do_with(req,{ write == 1'b1; addr == local::a; strb == 8'hFF; })
            `uvm_do_with(req,{ write == 1'b0; addr == local::a; })
            `uvm_do_with(req,{ write == 1'b1; addr == local::a; strb == 8'hFF; })
            `uvm_do_with(req,{ write == 1'b1; addr == local::a; strb != 8'h00; })
            `uvm_do_with(req,{ write == 1'b0; addr == local::a; })
        end

        // ---------------- 4. mixed traffic, small pool, ~15% invalid ----------------
        foreach(pool[i]) pool[i] = ($urandom_range(32'd0, 32'd65535) & 32'h0000_FFF8);
        repeat(num_mix) begin
            if($urandom_range(0,99) < 15) begin
                `uvm_do_with(req,{
                    ( addr >= 32'd65536 ) || ( addr[2:0] != 3'b000 );
                })
            end
            else begin
                a = pool[$urandom_range(0,7)];
                `uvm_do_with(req,{
                    addr == local::a;
                })
            end
        end

        `uvm_info(get_type_name(),"Back-to-Back Sequence Finished", UVM_LOW);
    endtask
endclass