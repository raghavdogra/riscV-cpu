module memoryMod
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
    input clk,
    input reset,


  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,



    input next_mem_active,	//current instruction uses a memory load/store or not
    input next_load,	//load if 1, store if 0, significant only when mem_active is set
    input [63:0] next_exmem_aluresult,
    input [5:0] next_exmem_rd,
   // input signed [63:0] exmem_rs2,
    input [63:0] target_pc,
    input EXMEM_ready,
    input EXMEM_rs2,

    output [63:0] memwb_aluresult,
    output [63:0] memwb_loadeddata,
    output [5:0] memwb_rd,
    output MEMWB_ready,
    output [5:0] MEMEX_rd,
    output [63:0] MEMEX_rdval,
    output MEMEX_stall,
    output dataselect	
);

    logic [63:0] exmem_aluresult;
    logic [5:0] exmem_rd;
    logic loadread;
    logic mem_active;
    logic in_data;

dcache
#(
  .BUS_TAG_WIDTH(13),
  .BUS_DATA_WIDTH(64)
)
i_dcache
(
  .clk(clk),
  .reset(reset),

  .stackptr(stackptr),

  // interface to connect to the bus
  .bus_reqcyc(bus_reqcyc),
  .bus_respack(bus_respack),
  .bus_req(bus_req),
  .bus_reqtag(bus_reqtag),
  .bus_respcyc(bus_respcyc),
  .bus_reqack(bus_reqack),
  .bus_resp(bus_resp),
  .bus_resptag(bus_resptag),

//cache input
  .mem_active(mem_active),
  .load(loadread), //request is read or write 1-read, 0-write
  .in_addr(exmem_aluresult), //aluresult from Execute
  .in_data(in_data),   //RS2 value

//cache output
  .memwb_loadeddata(memwb_loadeddata),
  .load_str_done(load_str_done),
  .MEMEX_stall(MEMEX_stall),
  .dataselect(dataselect)
);
logic mymemwb_ready;

always_ff @(posedge clk) begin
    if (reset) begin
    end
    else if(EXMEM_ready == 0) begin
        mymemwb_ready <= 0;

    end else begin
        mymemwb_ready <= 1;
end
end


always_comb begin
	if (MEMEX_stall == 1) begin
		MEMWB_ready = 0;
	end else begin
		MEMWB_ready = mymemwb_ready;
	end

end

always_ff @(posedge clk) begin
    if (reset) begin
    end
    else if(EXMEM_ready == 0) begin
    	//MEMWB_ready = 0;
		exmem_aluresult <= exmem_aluresult;
                exmem_rd <= exmem_rd;
		loadread <= loadread;
		mem_active <= mem_active;
		in_data <= in_data;
    end else begin
	//MEMWB_ready =1;
		if (MEMEX_stall == 0) begin
                	exmem_aluresult <= next_exmem_aluresult;
                	exmem_rd <= next_exmem_rd;
			loadread <= next_load;
			mem_active <= next_mem_active;
			in_data <= EXMEM_rs2;
		end else begin
			exmem_aluresult <= exmem_aluresult;
			in_data <= in_data;
                	exmem_rd <= exmem_rd;
			loadread <= loadread;
			mem_active <= mem_active;
		end

end
end

always_comb begin	
	memwb_aluresult = exmem_aluresult;
	memwb_rd = exmem_rd;
	MEMEX_rd = exmem_rd;
	MEMEX_rdval = exmem_aluresult;

end

endmodule
