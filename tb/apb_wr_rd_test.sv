class apb_wr_rd_seq extends apb_base_seq;
`uvm_object_utils(apb_wr_rd_seq)
int unsigned num_wr_rd = 50;
int unsigned num_partial = 50;
int unsigned num_rd_only = 30;

bit [31:0] written_addrs[$];

function new(string name = "apb_wr_rd_seq");
  super.new(name);
endfunction

virtual task body();
    bit [31:0] a;
    bit [31:0] pool[4];
    `uvm_info(get_type_name(),"Read Write Sequence Started :", UVM_LOW);
    repeat(num_wr_rd) begin
        `uvm_do_with (req,{
            write == 1'b1;
            strb == 1'hff;
            addr <= 32'd65536;
            addr[2:0] == 3'b000;
        })
        a = req.addr;
        written_addrs.push_back(a);
        `uvm_do_with(req,{
            write == 1'b0;
            // strb != 8'h00;
            addr == local::a;
        })
    end
    pool='{32'h0000_0000,32'h0000_0008,32'h0000_1000,32'h0000_FFF8};
    repeat(num_partial)begin
        a = pool[$urandom_range(0,3)];
        `uvm_do_with(req,{
            write == 1'b1;
            strb != 8'h00;
            addr == local::a;
        })
        written_addrs.push_back(a);
        `uvm_do_with(req,{
            write == 1'b0;
            // strb != 8'h00;
            addr == local::a;
        })
    end
    repeat(num_rd_only) begin
        a=written_addrs[$urandom_range(0,written_addrs.size()-1)];
        `uvm_do_with(req,{
            write == 1'b0;
            addr == local::a;
        })
    end
`uvm_info(get_type_name(),"Wr Rd Sequence Finished", UVM_LOW);

endtask

endclass