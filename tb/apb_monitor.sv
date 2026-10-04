class apb_mon extends uvm_monitor;
`uvm_component_utils(apb_mon)
   virtual apb_if vif;
   uvm_analysis_port #(apb_transaction) ap;
    function new(string name = "apb_mon", uvm_component parent = null);
        super.new(name , parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap",this);
        `uvm_info(get_type_name(),"apb_mon build phase", UVM_LOW);
         if(!uvm_config_db#(virtual apb_if):: get(this, " ", "vif", vif))
             `uvm_fatal(get_type_name(),"apb_mon: Vif not found in config db");
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"apb_mon run phase started ", UVM_LOW);
         forever begin
            @(posedge vif.PCLK);
            if(vif.PSELx && vif.PENABLE && vif.PREADY) begin
                apb_transaction tr=apb_transaction::type_id::create("tr");
                tr.addr=vif.PADDR;
                tr.write=vif.PWRITE;
                tr.wdata=vif.PWDATA;
                tr.rdata=vif.PRDATA;
                tr.slverr=vif.PSLVERR;
                tr.strb=vif.PSTRB;
                `uvm_info("Monitor", $sformatf("addr : 0x%0h | write : %0b | wdata : 0x%0h ", tr.addr, tr.write, tr.wdata), UVM_NONE);
                ap.write(tr);
            end
         end
    endtask
endclass
