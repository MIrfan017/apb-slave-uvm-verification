class apb_transaction extends uvm_sequence_item;
    rand bit [31:0]        addr;
    rand bit [63:0]        wdata;
    rand bit [7:0]         strb;
    rand bit               write;
         bit [63:0]        rdata;
         bit               slverr;
         bit               exp_err;
    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(slverr, UVM_ALL_ON)
        `uvm_field_int(exp_err, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction
endclass