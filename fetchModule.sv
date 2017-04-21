`include "cache.sv"
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
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,
  output [31:0] instr_reg,
  output [63:0] pc
);
wire data_ack;

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
	.instr_reg(instr_reg)
        );



 initial begin
	pc = entry;
  end

  always_ff @ (posedge clk) begin
	if(reset) begin
		pc = entry;
	end
	else begin
		if(data_ack == 1) begin
        		if(instr_reg == 8'h00008067) begin
				$finish;
			end
			$display("Instruction Register %x",instr_reg);
			pc = pc + 4'h4;
		end
	end
  end
endmodule
