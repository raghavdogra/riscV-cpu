`include "Sysbus.defs"
`include "decoder.sv"
module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,
  UPPER_WIDTH = BUS_DATA_WIDTH >> 1
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
  decoder get_decoder();

 
 logic [64:0] opcode;
  logic [63:0] pc;
  logic [63:0] npc;
  logic out_of_reset;
  logic [3:0] data_index;
  logic [UPPER_WIDTH - 1:0] upper;
  logic [UPPER_WIDTH - 1:0] lower;
  enum {fetchRequest=2'b10, fetchWaiting=2'b00, fetchReading=2'b01} fetchState, next_fetchState;
  
  always_comb begin
  case (fetchState)
	fetchRequest: begin
		if ({bus_reqack,bus_respcyc} == 2'b10) begin
                      next_fetchState = fetchWaiting;
		end
	end
	fetchWaiting: begin
		if ({bus_reqack,bus_respcyc} == 2'bx1) begin
			lower = bus_resp[UPPER_WIDTH - 1:0];
			upper = bus_resp[BUS_DATA_WIDTH-1:UPPER_WIDTH];
			next_fetchState = fetchReading;
		end
	end
	fetchReading: begin
		lower = bus_resp[UPPER_WIDTH - 1:0];
		upper = bus_resp[BUS_DATA_WIDTH-1:UPPER_WIDTH];
		if ({bus_reqack,bus_respcyc} == 2'bx0) begin
			npc = pc + 8'h40;
			bus_req = npc;
			bus_reqtag = `SYSBUS_READ << 8 | `SYSBUS_MEMORY << 12;	
			next_fetchState = fetchRequest;
		end
	end
  endcase
  end

  always_ff @ (posedge clk) begin
	if (reset) begin
		pc <= entry;
	end else begin
		if (out_of_reset == 0) begin
			npc = pc;
    			bus_reqtag = `SYSBUS_READ << 8 | `SYSBUS_MEMORY << 12;
			out_of_reset = 1;
    			bus_respack <= 0;
    			bus_req = pc;
	         	bus_reqcyc <= 1;
			fetchState <= fetchRequest;
		end else begin
			if (next_fetchState == fetchReading) begin
        			if (upper == 32'h00000000 && lower == 32'h00000000)
        				get_decoder.decode(lower, pc + data_index*4);
				else begin
        			get_decoder.decode(lower, pc + data_index*4);
        			get_decoder.decode(upper, pc + (data_index + 1) * 4 );
        			end
				
				if (upper == 32'h00000000) begin
          				 $finish;
        			end
        			if (lower == 32'h00000000) begin
          				$finish;
        			end
				data_index <= data_index +2;
			end
			pc <=npc;
			fetchState <=next_fetchState;
			bus_reqcyc <= next_fetchState[1];
			bus_respack <= next_fetchState[0];
		end
	end
  end 

  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
    data_index = 0;
    out_of_reset = 0;
  end
endmodule
