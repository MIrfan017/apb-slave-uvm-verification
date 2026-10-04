class apb_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils(apb_coverage)

    localparam int unsigned BASE_ADDR  = 0;
    localparam int unsigned MEM_SIZE_B = 64 * 1024;
    localparam int unsigned ALIGN      = 8;

    typedef enum {ADDR_VALID, ADDR_OOB, ADDR_MISALIGNED, ADDR_OOB_MISALIGNED} addr_class_e;

    virtual apb_if vif;

    // ---- sampled values ----
    bit [31:0]   addr;
    bit          is_write;
    bit [7:0]    strb;
    bit          slverr;
    bit          prev_write;
    bit          have_prev;
    addr_class_e addr_class;
    bit [2:0]    row_idx;

    // ---- b2b tracking ----
    bit          done_prev;      // a transfer completed on the previous clock edge
    bit          last_write;
    bit          last_err;
    bit          b2b_seen;       // 1 : next SETUP started right after ACCESS

    covergroup cg;
        option.per_instance = 1;

        cp_dir : coverpoint is_write {
            bins rd = {0};
            bins wr = {1};
        }

        cp_err : coverpoint slverr {
            bins no_err = {0};
            bins err    = {1};
        }

        cp_addr_class : coverpoint addr_class {
            bins valid          = {ADDR_VALID};
            bins oob            = {ADDR_OOB};
            bins misaligned     = {ADDR_MISALIGNED};
            bins oob_misaligned = {ADDR_OOB_MISALIGNED};
        }

        cp_boundary : coverpoint addr {
            bins first_word      = {32'h0000_0000};
            bins last_word       = {32'h0000_FFF8};
            bins last_byte       = {32'h0000_FFFF};
            bins first_oob       = {32'h0001_0000};
            bins max_addr        = {32'hFFFF_FFFF};
            bins oob_high        = {[32'h8000_0000 : 32'hFFFF_FFFE]};
            bins oob_low         = {[32'h0001_0001 : 32'h7FFF_FFFF]};
            bins valid_range     = {[32'h0000_0001 : 32'h0000_FFFE]};
        }

        cp_row : coverpoint row_idx iff (addr_class == ADDR_VALID) {
            bins row[] = {[0:7]};
        }

        cp_strb : coverpoint strb iff (is_write) {
            bins none       = {8'h00};
            bins full       = {8'hFF};
            bins lower_half = {8'h0F};
            bins upper_half = {8'hF0};
            bins lane[]     = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins other      = default;
        }

        cp_op_trans : coverpoint is_write iff (have_prev) {
            bins rd_to_rd = (0 => 0);
            bins rd_to_wr = (0 => 1);
            bins wr_to_rd = (1 => 0);
            bins wr_to_wr = (1 => 1);
        }

        x_dir_class : cross cp_dir, cp_addr_class;
        x_dir_err   : cross cp_dir, cp_err;
        x_dir_strb  : cross cp_dir, cp_strb {
            ignore_bins rd_strb = binsof(cp_dir.rd);
        }
    endgroup

    covergroup cg_b2b;
        option.per_instance = 1;

        cp_gap : coverpoint b2b_seen {
            bins idle_gap     = {0};
            bins back_to_back = {1};
        }
        cp_prev_dir : coverpoint last_write {
            bins prev_rd = {0};
            bins prev_wr = {1};
        }
        cp_prev_err : coverpoint last_err {
            bins prev_ok  = {0};
            bins prev_err = {1};
        }

        x_gap_dir : cross cp_gap, cp_prev_dir;
        x_gap_err : cross cp_gap, cp_prev_err;
    endgroup

    function new(string name = "apb_coverage", uvm_component parent = null);
        super.new(name , parent);
        cg     = new();
        cg_b2b = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual apb_if):: get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(),"apb_coverage: Vif not found in config db");
    endfunction

    // Called by the monitor for every completed transfer
    function void write(apb_transaction t);
        bit oob, misaligned;
        addr   = t.addr;
        is_write = t.write;
        strb   = t.strb;
        slverr = t.slverr;

        oob        = (t.addr < BASE_ADDR) || (t.addr >= (BASE_ADDR + MEM_SIZE_B));
        misaligned = ((t.addr % ALIGN) != 0);
        if     (!oob && !misaligned) addr_class = ADDR_VALID;
        else if( oob && !misaligned) addr_class = ADDR_OOB;
        else if(!oob &&  misaligned) addr_class = ADDR_MISALIGNED;
        else                         addr_class = ADDR_OOB_MISALIGNED;

        row_idx = t.addr[5:3];

        cg.sample();

        prev_write = t.write;
        have_prev  = 1'b1;
        last_write = t.write;
        last_err   = t.slverr;
    endfunction

    // Detect back-to-back: on the clock edge after a completed transfer, is
    // the bus already in SETUP of the next transfer (PSELx=1, PENABLE=0)?
    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.PCLK);
            if(done_prev) begin
                b2b_seen = (vif.PSELx === 1'b1) && (vif.PENABLE === 1'b0);
                cg_b2b.sample();
            end
            done_prev = (vif.PSELx === 1'b1) && (vif.PENABLE === 1'b1) && (vif.PREADY === 1'b1);
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("COV_SUMMARY","------------FUNCTIONAL COVERAGE-----------",UVM_NONE)
        `uvm_info("COV_SUMMARY",$sformatf("cg     (transfer coverage)  : %0.2f %%",cg.get_inst_coverage()),UVM_NONE)
        `uvm_info("COV_SUMMARY",$sformatf("cg_b2b (back-to-back)       : %0.2f %%",cg_b2b.get_inst_coverage()),UVM_NONE)
    endfunction
endclass