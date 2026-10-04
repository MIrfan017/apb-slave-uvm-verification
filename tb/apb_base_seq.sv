// class apb_base_seq extends uvm_sequence #(apb_transaction);
//     `uvm_object_utils(apb_base_seq)

//     function new(string name = "apb_base_seq");
//         super.new(name);
//         `uvm_info(get_type_name(),"sequence build phase", UVM_LOW);
//     endfunction

//     virtual task body();
   
//     `uvm_info(get_type_name(),"Sequence body started", UVM_LOW);
//     repeat(100)
//     `uvm_do_with(req,{req.strb==8'hff;req.write==1'b1;})

//     `uvm_info(get_type_name(),"Sequence body finish", UVM_LOW);
//     endtask
// endclass

class apb_base_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_base_seq)

    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction

    virtual task body();
   
    `uvm_info(get_type_name(),"Sequence body started", UVM_LOW);
    repeat(100)
    `uvm_do_with(req,{
        write == 1'b1;
        strb == 8'hff;
        addr < 32'd65536;
        addr[2:0] == 3'b000;
    })
    `uvm_info(get_type_name(),"Sequence body finish", UVM_LOW);
    endtask
endclass
