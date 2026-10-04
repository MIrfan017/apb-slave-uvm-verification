`include "uvm_macros.svh"
package apb_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "apb_transaction.sv"
`include "apb_sequencer.sv"
`include "apb_driver.sv"
`include "apb_b2b_driver.sv"
`include "apb_monitor.sv"
`include "apb_scoreboard.sv"
`include "apb_coverage.sv"
`include "apb_agent.sv"
`include "apb_env.sv"
`include "apb_base_seq.sv"
`include "apb_wr_rd_test.sv"
`include "apb_err_seq.sv"
`include "apb_err_alias_seq.sv"
`include "apb_b2b_seq.sv"
`include "apb_base_test.sv"
`include "apb_test.sv"
endpackage

module tb_top;
    import uvm_pkg::*;
    import apb_pkg::*;

    logic PCLK;
    logic PRESETn;
    initial PCLK=0;
    always #5 PCLK=~PCLK;
    initial begin
        PRESETn=0; 
        #20;
        PRESETn=1;
    end
    apb_if apb_intf(.PCLK(PCLK));
    apb_wrapper #(.ADDR_W(32),.DATA_W(64),.MEM_SIZE_K(64),.BASE_ADDR(0)) dut (
        .PCLK(PCLK),.PRESETn(PRESETn),.PSELx(apb_intf.PSELx),.PENABLE(apb_intf.PENABLE),.PWRITE(apb_intf.PWRITE),
        .PWDATA(apb_intf.PWDATA),.PSTRB(apb_intf.PSTRB),.PADDR(apb_intf.PADDR),.PRDATA(apb_intf.PRDATA),
        .PREADY(apb_intf.PREADY),.PSLVERR(apb_intf.PSLVERR)
    );
    initial begin
         uvm_config_db # (virtual apb_if)::set(null,"*","vif",apb_intf);
        `uvm_info("TB_TOP","Starting UVM Test ...", UVM_LOW);
        run_test("apb_base_test");
    end
    initial begin

        $vcdplusfile("waveform.vpd");
        $vcdpluson;

    end
endmodule