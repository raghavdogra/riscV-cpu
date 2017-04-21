`include "Sysbus.defs"
`include "fetchModule.sv"
`include "decodeModule.sv"
`include "registerfile.sv"
`include "executeModule.sv"
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
wire [63:0] pc;
wire [63:0] ifid_npc;
wire [63:0] target_pc;
wire branch;
wire signed [64:0] pcint;
fetchMod
#(
		.BUS_DATA_WIDTH(64),
		.BUS_TAG_WIDTH(13)
)
	i_fetch (
	.clk       (clk),
	.reset     (reset),
                    
	.entry     (entry),
	.stackptr (stackptr),                    
	.bus_reqcyc(bus_reqcyc),
	.bus_req   (bus_req),
	.bus_reqtag(bus_reqtag),
	.bus_reqack(bus_reqack),
                    
	.bus_respcyc(bus_respcyc),
	.bus_resp  (bus_resp),
	.bus_resptag(bus_resptag),
	.bus_respack(bus_respack),
	.instr_reg(instr_reg),
	.pc(pc),
	.ifid_npc(ifid_npc),
	.target_pc(target_pc),
	.branch(branch)
	);

wire [63:0] idex_npc;
wire [63:0] rs1;
wire [63:0] rs2;
wire [5:0] rd;
wire [19:0] immediate;
decodeMod
	i_decode (
	.clk(clk),
	.reset(reset),
	.instr_reg(instr_reg),
	.ifid_npc(ifid_npc),
	.idex_npc(idex_npc),
	.opcode(opcode),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),
	.immediate(immediate)
//	.pcint(pcint)
	);
executeMod
i_execute
(   
    .clk(clk),
    .reset(reset),
    .opcode(opcode),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .immediate(immediate),
    .idex_npc(idex_npc),
    .target_pc(target_pc),
    .branch(branch)
);



  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
