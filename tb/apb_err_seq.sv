class apb_err_seq extends apb_base_seq;
    `uvm_object_utils(apb_err_seq)

    int unsigned num_oob         = 30;
    int unsigned num_misalign    = 30;
    int unsigned num_oob_misalgn = 20;
    int unsigned num_mixed       = 40;

    function new(string name = "apb_err_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] a;
        bit [31:0] dir_addr[$];

        `uvm_info(get_type_name(),"Error Injection Sequence Started :", UVM_LOW);

        // ---------------- 1. Directed boundary addresses ----------------
        dir_addr = '{32'h0000_0000,   // first valid word
                     32'h0000_FFF8,   // last valid word
                     32'h0000_FFFC,   // last word, misaligned
                     32'h0000_FFFF,   // last byte, misaligned
                     32'h0001_0000,   // first OOB address
                     32'h0001_0008,
                     32'h0001_0001,   // OOB + misaligned
                     32'h0001_FFFF,
                     32'h0002_0000,
                     32'h8000_0000,
                     32'hFFFF_FFF8,
                     32'hFFFF_FFFF,
                     32'h0000_0001,   // misaligned in range
                     32'h0000_0004,
                     32'h0000_0007};
        foreach(dir_addr[i]) begin
            a = dir_addr[i];
            `uvm_do_with(req,{
                write == 1'b1;
                addr  == local::a;
            })
            `uvm_do_with(req,{
                write == 1'b0;
                addr  == local::a;
            })
        end

        // ---------------- 2. Out-of-bounds, aligned ----------------
        repeat(num_oob) begin
            `uvm_do_with(req,{
                addr >= 32'd65536;
                addr[2:0] == 3'b000;
            })
        end

        // ---------------- 3. Misaligned, inside memory range ----------------
        repeat(num_misalign) begin
            `uvm_do_with(req,{
                addr < 32'd65536;
                addr[2:0] != 3'b000;
            })
        end

        // ---------------- 4. Out-of-bounds and misaligned ----------------
        repeat(num_oob_misalgn) begin
            `uvm_do_with(req,{
                addr >= 32'd65536;
                addr[2:0] != 3'b000;
            })
        end

        // ---------------- 5. Random mix: valid and invalid ----------------
        repeat(num_mixed) begin
            `uvm_do_with(req,{
                addr dist { [32'd0 : 32'd65535] :/ 50, [32'd65536 : 32'hFFFF_FFFF] :/ 50 };
            })
        end

        `uvm_info(get_type_name(),"Error Injection Sequence Finished", UVM_LOW);
    endtask
endclass