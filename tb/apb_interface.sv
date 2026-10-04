// ---------- Interface ----------
interface apb_if(input logic PCLK);
    logic         PRESETn;
    logic         PSELx;
    logic         PENABLE;
    logic         PWRITE;
    logic [31:0]  PADDR;
    logic [63:0]  PWDATA;
    logic [7:0]   PSTRB;
    logic [63:0]  PRDATA;
    logic         PREADY;
    logic         PSLVERR;

endinterface