class apb_random_test extends apb_base_test;
`uvm_component_utils(apb_random_test)
 apb_base_seq seq;
function new(input string name = "apb_random_test", uvm_component c);
super.new(name,c);
endfunction
 
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"Test build phase", UVM_LOW);
seq = apb_base_seq::type_id::create("seq");
endfunction
 
task run_phase(uvm_phase phase);

phase.raise_objection(this);
`uvm_info(get_type_name(),"Test run phase", UVM_LOW)
seq.start(env.agent.sequencer);
phase.drop_objection(this);
`uvm_info(get_type_name(),"Test run phase: seq done", UVM_LOW);
endtask
endclass

class apb_wr_rd_test extends apb_base_test;
`uvm_component_utils(apb_wr_rd_test)
 apb_wr_rd_seq seq;
function new(input string name = "apb_wr_rd_test", uvm_component c);
super.new(name,c);
endfunction
 
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"Test build phase", UVM_LOW);
seq = apb_wr_rd_seq::type_id::create("seq");
endfunction
 
task run_phase(uvm_phase phase);

phase.raise_objection(this);
`uvm_info(get_type_name(),"Test run phase", UVM_LOW)
seq.start(env.agent.sequencer);
phase.drop_objection(this);
`uvm_info(get_type_name(),"Test run phase: seq done", UVM_LOW);
endtask
endclass

class apb_err_test extends apb_base_test;
`uvm_component_utils(apb_err_test)
 apb_err_seq seq;
function new(input string name = "apb_err_test", uvm_component c);
super.new(name,c);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"Test build phase", UVM_LOW);
seq = apb_err_seq::type_id::create("seq");
endfunction

task run_phase(uvm_phase phase);
phase.raise_objection(this);
`uvm_info(get_type_name(),"Test run phase", UVM_LOW)
seq.start(env.agent.sequencer);
#100;
phase.drop_objection(this);
`uvm_info(get_type_name(),"Test run phase: seq done", UVM_LOW);
endtask
endclass

class apb_err_alias_test extends apb_base_test;
`uvm_component_utils(apb_err_alias_test)
 apb_err_alias_seq seq;
function new(input string name = "apb_err_alias_test", uvm_component c);
super.new(name,c);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"Test build phase", UVM_LOW);
seq = apb_err_alias_seq::type_id::create("seq");
endfunction

task run_phase(uvm_phase phase);
phase.raise_objection(this);
`uvm_info(get_type_name(),"Test run phase", UVM_LOW)
seq.start(env.agent.sequencer);
#100;
phase.drop_objection(this);
`uvm_info(get_type_name(),"Test run phase: seq done", UVM_LOW);
endtask
endclass

class apb_b2b_test extends apb_base_test;
`uvm_component_utils(apb_b2b_test)
 apb_b2b_seq seq;
function new(input string name = "apb_b2b_test", uvm_component c);
super.new(name,c);
endfunction

virtual function void build_phase(uvm_phase phase);
// replace the normal driver with the back-to-back driver (before env is built)
apb_driver::type_id::set_type_override(apb_b2b_driver::get_type());
super.build_phase(phase);
`uvm_info(get_type_name(),"Test build phase", UVM_LOW);
seq = apb_b2b_seq::type_id::create("seq");
endfunction

task run_phase(uvm_phase phase);
phase.raise_objection(this);
`uvm_info(get_type_name(),"Test run phase", UVM_LOW)
seq.start(env.agent.sequencer);
#100;
phase.drop_objection(this);
`uvm_info(get_type_name(),"Test run phase: seq done", UVM_LOW);
endtask
endclass