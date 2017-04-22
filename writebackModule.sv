module writebackMod
(
input clk,
input reset,
input [5:0] dest_reg,
input [63:0] mewb_aluresult,
input MEMWB_ready
);


always_ff @(posedge clk) begin
	if(reset) begin
	end
	else if(MEMWB_ready == 0) begin
	end
	else begin
		regfile.gpr[dest_reg] = mewb_aluresult;
	end
end

endmodule

