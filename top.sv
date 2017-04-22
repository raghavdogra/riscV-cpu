`include "Sysbus.defs"
`include "fetchModule.sv"
`include "decodeModule.sv"
`include "registerfile.sv"
`include "executeModule.sv"
`include "memoryModule.sv"
`include "writebackModule.sv"
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



// Fetch Module Wires

wire [31:0] instr_reg;
wire IFID_ready;
wire [63:0] pc;
wire [63:0] IFID_npc;
wire [63:0] EXIF_targetpc;
wire EXIF_branch;
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

//outputs
	.pc(pc),
	.data_ack(IFID_ready),
	.instr_reg(instr_reg),
	.IFID_npc(IFID_npc),
	
//bus interface
	.bus_reqcyc(bus_reqcyc),
	.bus_req   (bus_req),
	.bus_reqtag(bus_reqtag),
	.bus_reqack(bus_reqack),
                    
	.bus_respcyc(bus_respcyc),
	.bus_resp  (bus_resp),
	.bus_resptag(bus_resptag),
	.bus_respack(bus_respack)
	);

wire [63:0] IDEX_npc;
wire [63:0] IDEX_rs1;
wire [63:0] IDEX_rs2;
wire [5:0] IDEX_rd;
wire [19:0] IDEX_immediate;
wire [63:0] IDEX_opcode;
wire IDEX_ready;

decodeMod
	i_decode (
//inputs
	.clk(clk),
	.reset(reset),
	.instr_reg(instr_reg),
	.IFID_npc(IFID_npc),
	.IFID_ready(IFID_ready),
	
//output
	.IDEX_ready(IDEX_ready),
	.IDEX_npc(IDEX_npc),
	.opcode(IDEX_opcode),
	.rs1(IDEX_rs1),
	.rs2(IDEX_rs2),
	.rd(IDEX_rd),
	.immediate(IDEX_immediate)
//	.pcint(pcint)
	);
wire [63:0]EXMEM_aluresult;
wire [5:0] EXMEM_rd;
wire EXMEM_ready;
wire mem_active;
wire load;

executeMod
i_execute
(   
//inputs
    .clk(clk),
    .reset(reset),
    .opcode(IDEX_opcode),
    .rd(IDEX_rd),
    .rs1(IDEX_rs1),
    .rs2(IDEX_rs2),
    .immediate(IDEX_immediate),
    .IDEX_npc(IDEX_npc),
    .IDEX_ready(IDEX_ready),
    

//outputs
    .EXMEM_ready(EXMEM_ready),
    .mem_active(mem_active),
    .load(load),
    .dest_reg(EXMEM_rd),
    .exmm_aluresult(EXMEM_aluresult),
    .target_pc(EXIF_targetpc),
    .branch(EXIF_branch)
);


    wire [63:0] MEMWB_aluresult;
    wire [63:0] MEMWB_loadeddata;
    wire [5:0] MEMWB_rd;
    wire MEMWB_ready;

memoryMod
i_memory
(
//inputs
    .clk(clk),
    .reset(reset),
    .mem_active(mem_active),
    .load(load),
    .exmem_aluresult(EXMEM_aluresult),
    .exmem_rd(EXMEM_rd),
    //.exmem_rs2(rs2),
    .target_pc(EXIM_targetpc),
    .EXMEM_ready(EXMEM_ready),

//outputs
    .memwb_aluresult(MEMWB_aluresult),
    .memwb_loadeddata(MEMWB_loadeddata),
    .memwb_rd(MEMWB_rd),
    .MEMWB_ready(MEMWB_ready)
);

writebackMod
i_writeback
(
	.clk(clk),
	.reset(reset),
	.dest_reg(MEMWB_rd),
	.mewb_aluresult(MEMWB_aluresult),
	.MEMWB_ready(MEMWB_ready)
);




  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
