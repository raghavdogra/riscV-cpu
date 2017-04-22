module memoryMod
(
    input clk,
    input reset,


    input mem_active,	//current instruction uses a memory load/store or not
    input load,	//load if 1, store if 0, significant only when mem_active is set
    input [63:0] exmem_aluresult,
    input [5:0] exmem_rd,
    input signed [63:0] exmem_rs2,
    input [63:0] target_pc,
    input data_ack,

    output [63:0] memwb_aluresult,
    output [63:0] memwb_loadeddata,
    output [5:0] memwb_rd
);

always_ff @(posedge clk) begin

    if (mem_active==1) begin
    end 
    else begin
		memwb_aluresult <= exmem_aluresult;
		memwb_rd <= exmem_rd;
    end
end

endmodule
