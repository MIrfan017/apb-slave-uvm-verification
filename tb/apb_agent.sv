class apb_agent extends uvm_agent;
`uvm_component_utils(apb_agent)
apb_driver driver;
apb_sequencer sequencer;
apb_mon monitor;

function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name , parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"Agent build phase", UVM_LOW);
    driver = apb_driver :: type_id::create("driver",this);
    sequencer = apb_sequencer :: type_id::create("sequencer",this);
    monitor = apb_mon :: type_id::create("monitor",this);
    // if(!uvm_config_db#(virtual apb_if):: get(this, " ", "vif",  ))
    //     `uvm_fatal(get_type_name(),"Driver: Vif not found in config db");
endfunction

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
endfunction
endclass