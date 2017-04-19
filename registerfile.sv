module registerfile(input clk, input reset, input dataready);

logic signed [63:0] gpr [31:0];

always_ff @(posedge clk) begin
	if(reset) begin
	end else begin
		if(dataready == 1)
			$display("Testing input ready");
		else
			 $display("Testing input not ready");

	end
end

endmodule
