class apb_sequencer extends uvm_sequencer #(apb_transaction);
    `uvm_component_utils(apb_sequencer)

    function new(input string name = "apb_sequencer" , uvm_component parent = null);
        super.new(name , parent);
        `uvm_info(get_type_name(),"sequence build phase", UVM_LOW);
    endfunction
endclass