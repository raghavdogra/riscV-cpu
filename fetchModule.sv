`include "cache.sv"
`define FETCHTERM

module fetchMod
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
  output [31:0] instr_reg,
  output [63:0] pc,      // Cache
  output [63:0] IFID_npc,      // Decode
  output data_ack,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,
  input  [63:0] EXIF_targetpc,
  input  EXIF_branch, 
  input  IDIF_stall,
  

// Bus Arbiter interface
  output icache_busreq,
  output icache_busidle,
  input icache_busgrant


);

cache
#(
                .BUS_DATA_WIDTH(64),
                .BUS_TAG_WIDTH(13)
)
        i_cache (
        .clk       (clk),
        .reset     (reset),

        .pc (pc),
        .stackptr (stackptr),
        .bus_reqcyc(bus_reqcyc),
        .bus_req   (bus_req),
        .bus_reqtag(bus_reqtag),
        .bus_reqack(bus_reqack),

        .bus_respcyc(bus_respcyc),
        .bus_resp  (bus_resp),
        .bus_resptag(bus_resptag),
        .bus_respack(bus_respack),
	.data_ack(data_ack),
	.instr_reg(instr_reg),
	.icache_busreq(icache_busreq),
        .icache_busidle(icache_busidle),
	.icache_busgrant(icache_busgrant)

        );

logic [63:0] npc;

 initial begin
	pc = entry;
  end

always_comb begin
    if(EXIF_branch == 0) begin
	npc = pc + 4'h4;
    end else begin
	npc = EXIF_targetpc;
//	$display("Got Target PC, %x", npc);
    end
end

  always_ff @ (posedge clk) begin
	if(reset) begin
		pc <= entry;
		regfile.gpr[2] <= stackptr;
	end
	else begin
		if(data_ack == 1 && IDIF_stall == 0) begin
`ifdef FETCHTERM
        		if(instr_reg == 8'h00) begin
				i_execute.printRegister;
				$finish;
			end
`endif
			pc <= npc;
			
//			$display("PC,%x  npc %x",pc,npc);
		end
	//	else
	//		instr_reg = 8'hFF;
	end
  end
endmodule
