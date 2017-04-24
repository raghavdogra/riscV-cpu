module writebackMod
(
input clk,
input reset,
input [5:0] dest_reg,
input [63:0] mewb_aluresult,
input MEMWB_ready,
output [5:0] WBEX_rd,
output [63:0] WBEX_rdval
);


always_ff @(posedge clk) begin
	if(reset) begin
	end
	else if(MEMWB_ready == 0) begin
	end
	else begin
		regfile.gpr[dest_reg] <= mewb_aluresult;
		WBEX_rdval <= regfile.gpr[dest_reg]; 
		//i_execute.printRegister;
	end
end

endmodule

