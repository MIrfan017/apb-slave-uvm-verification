class apb_b2b_driver extends apb_driver;
    `uvm_component_utils(apb_b2b_driver)

    function new(string name = "apb_b2b_driver", uvm_component parent = null);
        super.new(name , parent);
    endfunction

    task run_phase(uvm_phase phase);
        bit have_item = 1'b0;
        `uvm_info(get_type_name(),"B2B Driver run phase started ", UVM_LOW);
        forever begin
            if(!have_item) begin
                // Bus was idle: wait for an item and align to the clock edge
                seq_item_port.get_next_item(req);
                drive_idle();
                wait(vif.PCLK === 1'b1);
                @(posedge vif.PCLK);
            end
            `uvm_info(get_type_name(),$sformatf("B2B driving : addr = 0x%0h | write = %0d | wdata = 0x%0h | strb = 0x%0h",req.addr,req.write,req.wdata,req.strb), UVM_MEDIUM);
            drive_transfer_b2b(req);
            seq_item_port.item_done();

            seq_item_port.try_next_item(req);
            have_item = (req != null);
            if(!have_item) drive_idle();
        end
    endtask

    task drive_transfer_b2b (apb_transaction tr);
        int unsigned wait_cnt = 0;

        vif.PSELx   <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= tr.write;
        vif.PADDR   <= tr.addr;
        vif.PWDATA  <= tr.write ? tr.wdata : '0;
        vif.PSTRB   <= tr.write ? tr.strb  : '0;

        @(posedge vif.PCLK);
        vif.PENABLE <= 1'b1;

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
        tr.rdata  = vif.PRDATA;
        tr.slverr = vif.PSLVERR;
    endtask

endclass