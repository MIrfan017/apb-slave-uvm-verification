class apb_err_alias_seq extends apb_base_seq;
    `uvm_object_utils(apb_err_alias_seq)

    int unsigned num_iter = 20;

    function new(string name = "apb_err_alias_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] a;          // victim address (valid + aligned)
        bit [31:0] ea;         // alias address (invalid)
        bit [63:0] d_good;     // data written to the victim
        bit [63:0] d_bad;      // data written through alias addresses
        bit [31:0] alias_q[$];

        `uvm_info(get_type_name(),"Error Write Aliasing Sequence Started :", UVM_LOW);

        repeat(num_iter) begin
            a      = $urandom_range(32'd0, 32'd65535) & 32'h0000_FFF8;
            d_good = {$urandom(), $urandom()};
            d_bad  = ~d_good;

            // 1. legal write to victim
            `uvm_do_with(req,{
                write == 1'b1;
                addr  == local::a;
                wdata == local::d_good;
                strb  == 8'hFF;
            })

            alias_q.delete();
            alias_q.push_back(a + 32'h0001_0000);               // OOB alias
            alias_q.push_back(a + 32'h0010_0000);               // OOB alias
            alias_q.push_back(a | 32'h8000_0000);               // OOB alias
            alias_q.push_back(a + 32'h1);                       // misaligned alias
            alias_q.push_back(a + 32'h4);                       // misaligned alias
            alias_q.push_back(a + 32'h7);                       // misaligned alias
            alias_q.push_back(a + 32'h0001_0000 + 32'h3);       // OOB + misaligned

            foreach(alias_q[i]) begin
                ea = alias_q[i];

                // 2. illegal write through alias address
                `uvm_do_with(req,{
                    write == 1'b1;
                    addr  == local::ea;
                    wdata == local::d_bad;
                    strb  == 8'hFF;
                })
                if(req.slverr !== 1'b1)
                    `uvm_error("ALIAS_SEQ",$sformatf("Illegal write addr=0x%0h did not give PSLVERR",ea))

                // 3. victim must be unchanged
                `uvm_do_with(req,{
                    write == 1'b0;
                    addr  == local::a;
                })
                if(req.rdata !== d_good)
                    `uvm_error("ALIAS_SEQ",$sformatf("Memory corrupted by illegal write 0x%0h : victim 0x%0h expected = 0x%0h actual = 0x%0h",ea,a,d_good,req.rdata))

                // 4. read through alias address must also error
                `uvm_do_with(req,{
                    write == 1'b0;
                    addr  == local::ea;
                })
                if(req.slverr !== 1'b1)
                    `uvm_error("ALIAS_SEQ",$sformatf("Illegal read addr=0x%0h did not give PSLVERR",ea))
            end
        end

        `uvm_info(get_type_name(),"Error Write Aliasing Sequence Finished", UVM_LOW);
    endtask
endclass