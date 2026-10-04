class apb_scoreboard extends uvm_scoreboard;
`uvm_component_utils(apb_scoreboard)
uvm_analysis_imp #(apb_transaction , apb_scoreboard) item_export;

localparam int unsigned BASE_ADDR = 0;
localparam int unsigned MEM_SIZE_B = 64 * 1024;
localparam int unsigned DATA_W = 64;
localparam int unsigned STRB_W = DATA_W/8;
localparam int unsigned ALIGN = DATA_W/8;

protected byte unsigned ref_mem [bit[31:0]];

int unsigned num_total;
int unsigned num_writes, num_reads;
int unsigned num_err_expected;
int unsigned num_data_pass, num_data_fail, num_err_pass ,num_err_fail;
int unsigned num_bytes_unchecked , mismatch;

function new(string name = "apb_scoreboard", uvm_component parent = null);
    super.new(name , parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_export = new("item_export",this);
endfunction

function bit expected_err(bit [31:0] addr);
bit oob, misaligned;
oob=(addr<BASE_ADDR)||(addr>=(BASE_ADDR+MEM_SIZE_B));
misaligned=((addr%ALIGN)!=0);
return (oob||misaligned);
endfunction

function void write(apb_transaction tr);
    bit exp_err;
    bit [31:0] local_addr;
    num_total++;
    exp_err=expected_err(tr.addr);
    local_addr=tr.addr - BASE_ADDR;
    if(tr.write)num_writes++;
    else
    num_reads++;
    if(tr.slverr!==exp_err)begin
        num_err_fail++;
        `uvm_error ("SCB ERR",$sformatf("PSLVERR Mismatch: addr=0x%0h | write=%0b | expected = %0b | actual = %0b",tr.addr,tr.write,tr.exp_err,tr.slverr))
    end
    else begin
        num_err_pass++;
    end
    if(exp_err) begin
        num_err_expected++;
        `uvm_info("SCB",$sformatf("Error access handled: addr=0x%h | write = 0x%0b",tr.addr,tr.write),UVM_HIGH)
        return;
    end
    if(tr.write)begin
        for(int i=0; i<STRB_W; i++)begin
            if(tr.strb[i])
            ref_mem[local_addr+i] = tr.wdata[8*i+:8];
            end
        `uvm_info("SCB",$sformatf("Write addr = 0x%0h data 0x%0h strb = 0x%0h",tr.addr,tr.wdata,tr.strb),UVM_HIGH);
    end 
    else begin
            bit mismatch=0;
            bit [7:0] exp_byte;
            for(int i=0; i<STRB_W;i++) begin
                if(ref_mem.exists(local_addr+i))begin
                    exp_byte=ref_mem[local_addr+i];
                    if(tr.rdata[8*i+:8]!==exp_byte)
                    begin
                        mismatch = 1;
                        `uvm_error("SCB_DATA",$sformatf("Byte %0d mismatch 0x%0h: expected = 0x%02h actual = 0x%02h",i,tr.addr+1,exp_byte,tr.rdata[8*i+:8]))
                    end
                end
            end begin
                num_bytes_unchecked++;
            end
        end
    if(mismatch) num_data_fail++;
    else num_data_pass++;
    `uvm_info("SCB",$sformatf("Read addr = 0x%0h data = 0x%0h data = 0x%0h",tr.addr,tr.rdata,mismatch?"MISMATCH":"OK"),UVM_HIGH)
endfunction

function void report_phase(uvm_phase phase);
`uvm_info("SCB_SUMMARY","------------SCOREBOARD SUMMARY-----------",UVM_NONE)
`uvm_info("SCB_SUMMARY",$sformatf("Total Transfer :%0d",num_total),UVM_NONE)
`uvm_info("SCB_SUMMARY",$sformatf("Write/Read :%0d/%0d",num_writes,num_reads),UVM_NONE)
// `uvm_info("SCB_SUMMARY",$sformatf("Error Expected :%0d",num_err_expected),UVM_NONE)
`uvm_info("SCB_SUMMARY",$sformatf("PSLVERR Check pass/fail:%0d/%0d",num_err_pass,num_err_fail),UVM_NONE)
`uvm_info("SCB_SUMMARY",$sformatf("Read data Check pass/fail :%0d/%0d",num_data_pass,num_data_fail),UVM_NONE)
`uvm_info("SCB_SUMMARY",$sformatf("Unchecked read bytes (never written) :%0d",num_bytes_unchecked),UVM_NONE)

if(num_total==0)
`uvm_error("SCB_SUMMARY","No Transactions were observed - check monitor/driver connectivity")
endfunction
endclass