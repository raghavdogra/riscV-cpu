module dcache 
#(
  BUS_TAG_WIDTH = 13,
  BUS_DATA_WIDTH = 64, 
  ALLONES = 512'hFFFFFFFFFFFFFFFF
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
input mem_active,
input load, //request is read or write 1-read, 0-write
input [63:0] in_addr, //aluresult from Execute
//input [63:0] in_data,	//RS2 value
output [63:0] memwb_loadeddata,
output load_str_done,
output MEMEX_stall,
output dataselect



);


//logic [8:0] index [8:0];
logic [511:0] Set1data [511:0];
logic [48:0] Set1tag [511:0];
logic [511:0] Set2data [511:0];
logic [48:0] Set2tag [511:0];
logic Set1dirty [511:0];
logic Set2dirty [511:0];


logic [63:0] cacheLineAddress;

logic [511:0] hitCacheLine;
logic [511:0] missCacheLine;
logic [511:0] tempLD;

logic cache_hit;
logic [31:0] out_data;

logic [63:0] cache_line;
logic [63:0] prev_cacheLineAddress;
int BO;
enum {memoryRequest=2'b10, memoryWaiting=2'b00, memoryReading=2'b01, memoryIdle=2'b11} memoryState, next_memoryState;

//logic to check whether a tag is present in the cache, if yes->cache_hit, o.w. cache_miss
always_comb begin
	if (mem_active == 1 ) begin
		if (((in_addr[63:15]==Set1tag[in_addr[14:6]]) || (in_addr[63:15]==Set2tag[in_addr[14:6]])) && memoryState == memoryIdle) begin

			if (in_addr[63:15]==Set1tag[in_addr[14:6]] ) begin
				hitCacheLine = Set1data[in_addr[14:6]];
			end else begin
				hitCacheLine = Set2data[in_addr[14:6]];
			end
			tempLD = (ALLONES << (in_addr[5:3] * 64)) & hitCacheLine;
			//$display("our expression = %x", (ALLONES << (in_addr[5:2] * 32)));
			//$display("cacheLine      = %x", data[in_addr[14:6]]);
			//$display("tempIR         = %x", tempIR);
			memwb_loadeddata = tempLD >> (in_addr[5:3] * 64);
			//$display("instr_reg         = %x", instr_reg);	
			cache_hit = 1;
			dataselect = 1;
			MEMEX_stall = 0;
			//load_str_done = 1;
		
			//instr_reg = (in_addr[5])?data[in_addr[14:6]][63:32]:data[in_addr[14:6]][31:0];
			//BO =  in_addr[5:2]; 
			//instr_reg = data[in_addr[14:6]][];
		end else begin
			//load_str_done = 0;
			cache_hit = 0;	//to start memory fetch
			MEMEX_stall = 1;	
			//instr_reg = 0;
		end
	end else begin
		MEMEX_stall = 0;
		dataselect = 0;
		cache_hit = 1;
	end
end


/*
always_ff @(posedge clk) begin
	if (cache_hit == 1) begin
		load_str_done <= 1;
		instr_reg <= out_data;
	end else begin
		load_str_done <= 0;
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
			cacheLineAddress = in_addr;
                        next_memoryState = memoryReading;
                end
        end
        memoryReading: begin
		cache_line = bus_resp;
		cacheLineAddress = prev_cacheLineAddress + 40'h8;
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
		missCacheLine <= 0;
	end
	if(cache_hit==0 && memoryState == memoryIdle  && !reset) begin
                        bus_reqtag <= `SYSBUS_READ << 8 | `SYSBUS_MEMORY << 12;
                        bus_respack <= 0;
                        bus_req <= in_addr;
                        bus_reqcyc <= 1;
                        memoryState <= memoryRequest;
			missCacheLine <= 0;
	end
	if (next_memoryState == memoryReading) begin
        	//if(cache_line == 64'h0000000000000000)
		//	$finish;
	//	else begin
			
			missCacheLine <= missCacheLine | cache_line << (64 * cacheLineAddress[5:3]);
			//Set1data[cacheLineAddress[14:6]] <= Set1data[cacheLineAddress[14:6]] | cache_line << (64* cacheLineAddress[5:3]);
		       //data[cacheLineAddress[14:6]][31:0] <= cache_line;
			//Set1tag[in_addr[14:6]] <= in_addr[63:15];
			prev_cacheLineAddress <= cacheLineAddress;
	//	end
	end
	if (memoryState == memoryReading && next_memoryState == memoryIdle) begin
		if (($random()<0)) begin
			$display("using Set 1");
			Set1data[in_addr[14:6]] <= missCacheLine;
			Set1tag[in_addr[14:6]] <= in_addr[63:15];
		end else begin
			$display("using Set 2");
			Set2data[in_addr[14:6]] <= missCacheLine;
			Set2tag[in_addr[14:6]] <= in_addr[63:15];
		end
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
	Set1tag[i] = 48'hdeadbeefdead;
	Set2tag[i] = 48'hbeefdeadbeef;
end
end	
endmodule
		
