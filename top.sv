`include "Sysbus.defs"
`include "fetchModule.sv"
`include "decodeModule.sv"
`include "registerfile.sv"
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
	.pc(pc)
	);
decodeMod
	i_decode (
	.clk(clk),
	.reset(reset),
	.instr_reg(instr_reg),
	.pc(pc),
	.opcode(opcode),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),
	.immediate(immediate),
	.pcint(pcint)
	);


  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
endmodule
