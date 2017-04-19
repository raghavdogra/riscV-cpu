module cache 
#(
  BUS_TAG_WIDTH = 13,
  BUS_DATA_WIDTH = 64, 
  ALLONES = 32'hFFFFFFFF
)
(
  input  clk,
         reset,

input [63:0] stackptr,

  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,

//interface to the core

input [63:0] pc,
output [31:0] instr_reg,
output data_ack

);


//logic [8:0] index [8:0];
logic [511:0] data [511:0];
logic [48:0] tag [511:0];
logic [63:0] cacheLineAddress;



logic cache_hit;
logic [31:0] out_data;

logic [63:0] cache_line;
logic [63:0] prev_cacheLineAddress;
int BO;
enum {memoryRequest=2'b10, memoryWaiting=2'b00, memoryReading=2'b01, memoryIdle=2'b11} memoryState, next_memoryState;

//logic to check whether a tag is present in the cache, if yes->cache_hit, o.w. cache_miss
always_comb begin

	if (pc[63:15]==tag[pc[14:6]]) begin

		cache_hit = 1;
		data_ack = 1;
		instr_reg = (ALLONES << pc[5:2] * 32) & data[pc[14:6]];
		//instr_reg = (pc[5])?data[pc[14:6]][63:32]:data[pc[14:6]][31:0];
	//	BO =  pc[5:2]; 
		//instr_reg = data[pc[14:6]][];
	end else begin
		data_ack = 0;
		cache_hit = 0;
		
		//instr_reg = 0;
	end
end


/*
always_ff @(posedge clk) begin
	if (cache_hit == 1) begin
		data_ack <= 1;
		instr_reg <= out_data;
	end else begin
		data_ack <= 0;
		instr_reg <= out_data;
	end
end
*/


  always_comb begin
  case (memoryState)
        memoryRequest: begin
                if ({bus_reqack,bus_respcyc} == 2'b10) begin
                      next_memoryState = memoryWaiting;
                end
        end
        memoryWaiting: begin
                if ({bus_reqack,bus_respcyc} == 2'bx1) begin
			cache_line = bus_resp;
			cacheLineAddress = pc;
                        next_memoryState = memoryReading;
                end
        end
        memoryReading: begin
		cache_line = bus_resp;
		cacheLineAddress = prev_cacheLineAddress + 40'h40;
                if ({bus_reqack,bus_respcyc} == 2'bx0) begin
                        next_memoryState = memoryIdle;
                end
        end
	memoryIdle: begin
		
	end	
  endcase
  end


always_ff @(posedge clk) begin
        if (reset) begin
                memoryState <= memoryIdle;
		next_memoryState = memoryIdle;
	end
	if(cache_hit==0 && memoryState == memoryIdle && !reset) begin
                        bus_reqtag <= `SYSBUS_READ << 8 | `SYSBUS_MEMORY << 12;
                        bus_respack <= 0;
                        bus_req <= pc;
                        bus_reqcyc <= 1;
                        memoryState <= memoryRequest;
			data[pc[14:6]] = 0;
	end
	if (next_memoryState == memoryReading) begin
        	//if(cache_line == 64'h0000000000000000)
		//	$finish;
	//	else begin
			
			
			data[cacheLineAddress[14:6]] <= data[cacheLineAddress[14:6]] | cache_line << pc[5:3];
		       //data[cacheLineAddress[14:6]][31:0] <= cache_line;
			tag[cacheLineAddress[14:6]] <= cacheLineAddress[63:15];
			prev_cacheLineAddress <= cacheLineAddress;
	//	end
	end
end

always_ff @(posedge clk) begin
	memoryState <= next_memoryState;
	if (next_memoryState != memoryIdle) begin
                        bus_reqcyc <= next_memoryState[1];
                        bus_respack <= next_memoryState[0];
        end     
	
end
initial begin
int i;
for (i = 0; i < 512; i = i +1) begin
	tag[i] = 48'hffffffffffff;
end
end	
endmodule
		
