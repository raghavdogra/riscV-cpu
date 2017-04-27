module memoryMod
(
    input clk,
    input reset,


    input mem_active,	//current instruction uses a memory load/store or not
    input load,	//load if 1, store if 0, significant only when mem_active is set
    input [63:0] next_exmem_aluresult,
    input [5:0] next_exmem_rd,
   // input signed [63:0] exmem_rs2,
    input [63:0] target_pc,
    input EXMEM_ready,

    output [63:0] memwb_aluresult,
    output [63:0] memwb_loadeddata,
    output [5:0] memwb_rd,
    output MEMWB_ready,
    output [5:0] MEMEX_rd,
    output [63:0] MEMEX_rdval,
    output MEMEX_stall
);

    logic [63:0] exmem_aluresult;
    logic [5:0] exmem_rd;



always_ff @(posedge clk) begin
    if (reset) begin
    end
    else if(EXMEM_ready == 0) begin
        MEMWB_ready <= 0;

    end else begin
        MEMWB_ready <= 1;
end
end




always_ff @(posedge clk) begin
    if (reset) begin
    end
    else if(EXMEM_ready == 0) begin
    	//MEMWB_ready = 0;
		exmem_aluresult <= exmem_aluresult;
                exmem_rd <= exmem_rd;

    end else begin
	//MEMWB_ready =1;
    	if (mem_active==1) begin
    	end 
    	else begin
                exmem_aluresult <= next_exmem_aluresult;
                exmem_rd <= next_exmem_rd;
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
