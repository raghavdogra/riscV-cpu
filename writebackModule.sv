module writebackMod
(
input clk,
input reset,
input [5:0] dest_reg,
input [63:0] mewb_aluresult,
input [63:0] memwb_loadeddata,
input dataselect,
input MEMWB_wbactive,
input MEMWB_ready,
output [5:0] WBEX_rd,
output [63:0] WBEX_rdval,
output WBEX_wbactive
);

logic mymemwb_wbactive;

always_ff @(posedge clk) begin
	if(reset) begin
	end
	else if(MEMWB_ready == 0) begin
	end
	else begin
	if (MEMWB_wbactive == 1) begin
		if (dataselect == 0) begin
			regfile.gpr[dest_reg] <= mewb_aluresult;
			//i_execute.printRegister;
		end else begin
			regfile.gpr[dest_reg] <= memwb_loadeddata;	
		end
	end
end
end

always_ff @(posedge clk) begin
        if(reset) begin
        end
        else begin
	mymemwb_wbactive <= MEMWB_wbactive;
	end
end


always_comb begin
	WBEX_rdval = regfile.gpr[dest_reg]; 
	WBEX_rd = dest_reg;
	WBEX_wbactive = mymemwb_wbactive;
end


endmodule

