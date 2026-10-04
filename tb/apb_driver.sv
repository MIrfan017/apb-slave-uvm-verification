class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils(apb_driver)
    virtual apb_if vif;
    int unsigned timeout_cycles = 100;
    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name , parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"Driver build phase", UVM_LOW);
         if(!uvm_config_db#(virtual apb_if):: get(this, " ", "vif", vif))
             `uvm_fatal(get_type_name(),"Driver: Vif not found in config db");
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"Driver run phase started ", UVM_LOW);
         forever begin
            seq_item_port.get_next_item(req);
            `uvm_info(get_type_name(),$sformatf("Driving transaction : addr = 0x%0h | write = %0d | wdata = 0x0%0h ",req.addr,req.write,req.wdata), UVM_MEDIUM);
            drive_idle();
            wait(vif.PCLK === 1'b1);
            @(posedge vif.PCLK);

            drive_transfer(req);

            seq_item_port.item_done();
         end
    endtask

    task drive_idle();
    vif.PSELx<=1'b0;
    vif.PENABLE<=1'b0;
    vif.PWRITE<=1'b0;
    vif.PADDR<=1'b0;
    vif.PWDATA<=1'b0;
    vif.PSTRB<=1'b0;
    endtask

    task drive_transfer (apb_transaction tr);
    int unsigned wait_cnt = 0;

    vif.PSELx<=1'b1;
    vif.PENABLE<=1'b0;
    vif.PWRITE<= tr.write;
    vif.PADDR<= tr.addr;
    vif.PWDATA<= tr.write ? tr.wdata : '0;
    vif.PSTRB<= tr.write ? tr.strb : '0;

    @(posedge vif.PCLK);
    vif.PENABLE<=1'b1;

    do begin
        @(posedge vif.PCLK);
        wait_cnt++;
        if(wait_cnt > timeout_cycles)
        begin
            `uvm_info("Driver", $sformatf("Time out : addr = 0x%0h",tr.addr),UVM_LOW)
            break;
        end
    end
    while (vif.PREADY !== 1'b1);
    tr.rdata = vif.PRDATA;
    tr.slverr = vif.PSLVERR;

    vif.PSELx <= 1'b0;
    vif.PENABLE <= 1'b0;
    endtask


endclass
