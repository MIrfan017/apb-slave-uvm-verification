class apb_env extends uvm_env;
`uvm_component_utils(apb_env)
apb_agent agent;
apb_scoreboard scb;
apb_coverage cov;
function new(input string name = "apb_env", uvm_component c);
super.new(name,c);
endfunction
 
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"Env build phase", UVM_LOW);
agent = apb_agent:: type_id::create("agent",this);
scb = apb_scoreboard:: type_id::create("scb",this);
cov = apb_coverage:: type_id::create("cov",this);
endfunction
 
virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"Env connect phase", UVM_LOW);
agent.monitor.ap.connect(scb.item_export);
agent.monitor.ap.connect(cov.analysis_export);
endfunction
 
endclass