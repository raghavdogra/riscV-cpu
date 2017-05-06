`include "Sysbus.defs"
`include "fetchModule.sv"
`include "decodeModule.sv"
`include "registerfile.sv"
`include "executeModule.sv"
`include "memoryModule.sv"
`include "writebackModule.sv"
`include "busarbiter.sv"
module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input  clk,
         reset,

  // 64-bit addresses of the program entry point and initial stack pointer
  input  [63:0] entry,
  input  [63:0] stackptr,
  input  [63:0] satp,
  
  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag

);

registerfile regfile();

wire icache_busreq;
wire dcache_busreq;
wire icache_busidle;
wire dcache_busidle;
wire icache_busgrant;
wire dcache_busgrant;

busarbiter
i_busarbiter(


.icache_busreq(icache_busreq),
.dcache_busreq(dcache_busreq),
.icache_busidle(icache_busidle),
.dcache_busidle(dcache_busidle),
.icache_busgrant(icache_busgrant),
.dcache_busgrant(dcache_busgrant)

);


// Fetch Module Wires

wire [31:0] IFID_instreg;
wire IFID_ready;
wire [63:0] pc;
wire [63:0] IFID_npc;
wire signed [64:0] pcint;
fetchMod
#(
		.BUS_DATA_WIDTH(64),
		.BUS_TAG_WIDTH(13)
)
	i_fetch (
//inputs
	.clk       (clk),
	.reset     (reset),
                    
	.entry     (entry),
	.stackptr (stackptr),
	
	.EXIF_targetpc(EXIF_targetpc),
	.EXIF_branch(EXIF_branch),
	.IDIF_stall(IDIF_stall),

//outputs
	.pc(pc),
	.data_ack(IFID_ready),
	.instr_reg(IFID_instreg),
	.IFID_npc(IFID_npc),
	
//bus interface
	.bus_reqcyc(bus_reqcyc),
	.bus_req   (bus_req),
	.bus_reqtag(bus_reqtag),
	.bus_reqack(bus_reqack),
                    
	.bus_respcyc(bus_respcyc),
	.bus_resp  (bus_resp),
	.bus_resptag(bus_resptag),
	.bus_respack(bus_respack),


// bus arbiter interface
	.icache_busreq(icache_busreq),
	.icache_busidle(icache_busidle),
	.icache_busgrant(icache_busgrant)



	);

// Decode Module Wires
wire [63:0] IDEX_npc;
wire [63:0] IDEX_rs1;
wire [63:0] IDEX_rs2;
wire [5:0] IDEX_rd;
wire [19:0] IDEX_immediate;
wire [63:0] IDEX_opcode;
wire IDEX_ready;
wire [5:0] IDEX_rs1reg;
wire [5:0] IDEX_rs2reg;
wire IDIF_stall;

decodeMod
	i_decode (
//inputs
	.clk(clk),
	.reset(reset),
	.IFID_instreg(IFID_instreg),
	.IFID_npc(pc),
	.IFID_ready(IFID_ready),
	.EXID_stall(EXID_stall),
	.EXIF_branch(EXIF_branch),
	
//output
	.IDEX_ready(IDEX_ready),
	.IDEX_npc(IDEX_npc),
	.opcode(IDEX_opcode),
	.rs1(IDEX_rs1),
	.rs2(IDEX_rs2),
	.rd(IDEX_rd),
	.immediate(IDEX_immediate),
	.IDEX_rs1reg(IDEX_rs1reg),
        .IDEX_rs2reg(IDEX_rs2reg),
        .IDIF_stall(IDIF_stall)
//	.pcint(pcint)
	);

wire EXMEM_wbactive;
wire [63:0]EXMEM_aluresult;
wire [5:0] EXMEM_rd;
wire [63:0] EXMEM_rs2;
wire EXMEM_ready;
wire mem_active;
wire load;
wire EXID_stall;
wire EXIF_branch;
wire [63:0] EXIF_targetpc;


executeMod
i_execute
(   
//inputs
    .clk(clk),
    .reset(reset),
    .next_opcode(IDEX_opcode),
    .next_rd(IDEX_rd),
    .next_rs1(IDEX_rs1),
    .next_rs2(IDEX_rs2),
    .next_rs1reg(IDEX_rs1reg),
    .next_rs2reg(IDEX_rs2reg),
    .next_immediate(IDEX_immediate),
    .next_IDEX_npc(IDEX_npc),
    .IDEX_ready(IDEX_ready),
    .MEMEX_rd(MEMEX_rd),
    .WBEX_rd(WBEX_rd),
    .MEMEX_rdval(MEMEX_rdval),
    .WBEX_rdval(WBEX_rdval),
    .MEMEX_stall(MEMEX_stall),
    .WBEX_wbactive(WBEX_wbactive),
    .MEMEX_wbactive(MEMEX_wbactive),
//outputs
    .EXMEM_ready(EXMEM_ready),
    .mem_active(mem_active),
    .load(load),
    .dest_reg(EXMEM_rd),
    .EXMEM_rs2(EXMEM_rs2),
    .exmm_aluresult(EXMEM_aluresult),
    .target_pc(EXIF_targetpc),
    .branch(EXIF_branch),
    .EXID_stall(EXID_stall),
    .EXMEM_wbactive(EXMEM_wbactive)
);

    wire MEMWB_wbactive;
    wire [63:0] MEMWB_aluresult;
    wire [63:0] MEMWB_loadeddata;
    wire [5:0] MEMWB_rd;
    wire MEMWB_ready;
    wire [5:0] MEMEX_rd;
    wire [63:0] MEMEX_rdval;
    wire MEMEX_stall;
    wire dataselect;
    wire MEMEX_wbactive;
memoryMod
#(              
                .BUS_DATA_WIDTH(64),
                .BUS_TAG_WIDTH(13)
)
i_memory
(
//inputs
    .clk(clk),
    .reset(reset),
    .next_mem_active(mem_active),
    .next_load(load),
    .next_exmem_aluresult(EXMEM_aluresult),
    .next_exmem_rd(EXMEM_rd),
    .EXMEM_rs2(EXMEM_rs2),
    .target_pc(EXIF_targetpc),
    .EXMEM_ready(EXMEM_ready),
    .EXMEM_wbactive(EXMEM_wbactive),

//outputs
    .MEMEX_wbactive(MEMEX_wbactive),
    .memwb_aluresult(MEMWB_aluresult),
    .memwb_loadeddata(MEMWB_loadeddata),
    .memwb_rd(MEMWB_rd),
    .MEMWB_ready(MEMWB_ready),
    .MEMEX_rd(MEMEX_rd),
    .MEMEX_rdval(MEMEX_rdval),
    .MEMEX_stall(MEMEX_stall),
    .dataselect(dataselect),
    .MEMWB_wbactive(MEMWB_wbactive),

//bus interface
        .bus_reqcyc(bus_reqcyc),
        .bus_req   (bus_req),
        .bus_reqtag(bus_reqtag),
        .bus_reqack(bus_reqack),

        .bus_respcyc(bus_respcyc),
        .bus_resp  (bus_resp),
        .bus_resptag(bus_resptag),
        .bus_respack(bus_respack),
//Bus Arbiter Interface
	.dcache_busreq(dcache_busreq),
        .dcache_busidle(dcache_busidle),
	.dcache_busgrant(dcache_busgrant)

);

wire [5:0] WBEX_rd;
wire [63:0] WBEx_rdval;
wire WBEX_wbactive;
writebackMod
i_writeback
(
	.clk(clk),
	.reset(reset),
	.dest_reg(MEMWB_rd),
	.MEMWB_wbactive(MEMWB_wbactive),
	.dataselect(dataselect),
	.mewb_aluresult(MEMWB_aluresult),
	.MEMWB_ready(MEMWB_ready),
	.WBEX_rd(WBEX_rd),
	.memwb_loadeddata(MEMWB_loadeddata),
	.WBEX_rdval(WBEX_rdval),
	.WBEX_wbactive(WBEX_wbactive)
);




  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
