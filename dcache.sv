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
input [63:0] in_data,	//RS2 value
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
logic [63:0] prev_in_addr;
logic writeback;

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
		if (((in_addr[63:15]==Set1tag[in_addr[14:6]]) || (in_addr[63:15]==Set2tag[in_addr[14:6]])) && memoryState == memoryIdle) begin //if cache hit

			if (in_addr[63:15]==Set1tag[in_addr[14:6]] ) begin
				hitCacheLine = Set1data[in_addr[14:6]];
			end else begin
				hitCacheLine = Set2data[in_addr[14:6]];
			end
			if (load==1) begin
				tempLD = (ALLONES << (in_addr[5:3] * 64)) & hitCacheLine;
				//$display("our expression = %x", (ALLONES << (in_addr[5:2] * 32)));
				//$display("cacheLine      = %x", data[in_addr[14:6]]);
				//$display("tempIR         = %x", tempIR);
				memwb_loadeddata = tempLD >> (in_addr[5:3] * 64);
				//$display("instr_reg         = %x", instr_reg);	
				cache_hit = 1;
				dataselect = 1;
				MEMEX_stall = 0;
				writeback = 0;
				//load_str_done = 1;
			
				//instr_reg = (in_addr[5])?data[in_addr[14:6]][63:32]:data[in_addr[14:6]][31:0];
				//BO =  in_addr[5:2]; 
				//instr_reg = data[in_addr[14:6]][];
			end else begin
				//making those 8 bytes to be zero
				tempLD = (ALLONES << (in_addr[5:3] * 64));
				tempLD = ~tempLD;
				hitCacheLine = hitCacheLine & tempLD;
				//writing the 8 bytes of in_data to the desired location
				tempLD = in_data << (in_addr[5:3] * 64);
				hitCacheLine = hitCacheLine | tempLD;
				prev_in_addr = in_addr;
				writeback = 1;

				cache_hit = 1;
				dataselect = 0;
				MEMEX_stall = 0;
			end
		end else begin //cache miss case
			//load_str_done = 0;
			cache_hit = 0;	//to start memory fetch
			MEMEX_stall = 1;	
			dataselect = 0;
			//instr_reg = 0;
			writeback = 0;
		end
	end else begin //not a memory instruction
		MEMEX_stall = 0;
		dataselect = 0;
		cache_hit = 1;
		writeback = 0;
	end
end



always_ff @(posedge clk) begin
	if (writeback == 1) begin
			if (prev_in_addr[63:15]==Set1tag[prev_in_addr[14:6]] ) begin
				$display(" writing using Set 1");
				Set1data[prev_in_addr[14:6]] <= hitCacheLine;
				Set1tag[prev_in_addr[14:6]] <= prev_in_addr[63:15];
				Set1dirty[prev_in_addr[14:6]] <= 1;
			end else begin
				$display(" writing using Set 2");
				$display("hcl= %x ",hitCacheLine);
				Set2data[prev_in_addr[14:6]] <= hitCacheLine;
				Set2tag[prev_in_addr[14:6]] <= prev_in_addr[63:15];
				Set2dirty[prev_in_addr[14:6]] <= 1;
			end
	
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
				if(Set1dirty[in_addr[14:6]] == 0) begin
					Set1data[in_addr[14:6]] <= missCacheLine;
					Set1tag[in_addr[14:6]] <= in_addr[63:15];
					Set1dirty[in_addr[14:6]] <= 0;
				end else begin
					dirtyWriteback <= 1;
					dirtyCacheLine <= Set1data[in_addr[14:6]];
					write_addr <= {Set1tag[in_addr[14:6]],in_addr[14:6],6'b000000};
					way <= 1;
				end
			end else begin
				$display("using Set 2");
				if(Set2dirty[in_addr[14:6]] == 0) begin
					Set2data[in_addr[14:6]] <= missCacheLine;
					Set2tag[in_addr[14:6]] <= in_addr[63:15];
					Set2dirty[in_addr[14:6]] <= 0;
				end else begin
					dirtyWriteback <= 1;
					dirtyCacheLine <= Set2data[in_addr[14:6]];
					write_addr <= {Set2tag[in_addr[14:6]],in_addr[14:6],6'b000000};
					way <= 2;
				end
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
logic [511:0] dirtyCacheLine;
logic dirtyWriteback;
logic [63:0] write_addr;
logic way;
logic dirtywritebackstage;
logic datawritebegin;
logic [63:0] latcheddata;
int ncyclecount;
int cyclecount;
logic nbus_reqcyc;
always_comb begin
if(dirtywritebackstage == 1) begin
	
	if(bus_reqack == 1) begin
		datawritebegin = 1;
		ncyclecount = 1;
	end
	if(ncyclecount > 0) begin
		ncyclecount = cyclecount + 1;
	end
	case (ncyclecount)
        	0: begin
                end
		1: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[63:0];		
		end 
		2: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[127:64];
		end
		3: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[191:128];		
		end 
		4: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[255:192];		
		end 
		5: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[319:256];
		end
		6: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[383:320];		
		end 
		7: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[447:384];		
		end 
		8: begin
			nbus_reqcyc = 1;
			latcheddata = dirtyCacheLine[511:448];
		end
		9: begin
			nbus_reqcyc = 0;
			latcheddata = 0;
		end
		10: begin
			datawritebegin = 0;	
		end
  	endcase

end
end

always_ff @(posedge clk) begin
        if (dirtyWriteback == 1) begin
		dirtyWriteback <= 0;
		dirtywritebackstage <= 1; 
		bus_reqtag <= `SYSBUS_WRITE << 8 | `SYSBUS_MEMORY << 12;
                bus_respack <= 0;
                bus_req <= write_addr;
                bus_reqcyc <= 1;
		cyclecount <=0;
		
	end
	if(dirtywritebackstage == 1) begin
		if(datawritebegin == 1) begin
			bus_reqcyc <= nbus_reqcyc;
			bus_req <= latcheddata; //latch address first
			cyclecount <= ncyclecount;
		end
		if(ncyclecount == 10) begin
			dirtywritebackstage <= 0;
			if(way == 1) begin
				Set1data[in_addr[14:6]] <= missCacheLine;
				Set1tag[in_addr[14:6]] <= in_addr[63:15];
				Set1dirty[in_addr[14:6]] <= 0;
				way <= 0;
			end
			if(way == 2) begin
				Set2data[in_addr[14:6]] <= missCacheLine;
				Set2tag[in_addr[14:6]] <= in_addr[63:15];
				Set2dirty[in_addr[14:6]] <= 0;
				way <= 0;
			end
		end
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
		
