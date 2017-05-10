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
input MEMWB_ecall,

input MEMWB_pend_write,
input [3:0] MEMWB_size,
input [63:0] MEMWB_value,
input [63:0] MEMWB_addr,

output ecalldone,
output [5:0] WBEX_rd,
output [63:0] WBEX_rdval,
output WBEX_wbactive
);

logic mymemwb_wbactive;
logic myecalldone;

always_ff @(posedge clk) begin
	if(reset) begin
	end
	else if(MEMWB_ready == 0) begin
		myecalldone <= myecalldone;
	end
	else begin
	if (MEMWB_wbactive == 1) begin
		if (dataselect == 0) begin
			regfile.gpr[dest_reg] <= mewb_aluresult;
			//i_execute.printRegister;
		end else begin
			regfile.gpr[dest_reg] <= memwb_loadeddata;	
		end
		myecalldone <= 0;
	end else if (MEMWB_ecall == 1) begin
		do_ecall(regfile.gpr[17], regfile.gpr[10], regfile.gpr[11], regfile.gpr[12], regfile.gpr[13], regfile.gpr[14], regfile.gpr[15], regfile.gpr[16], regfile.gpr[10]);
		myecalldone <= 1;
	end
	if (MEMWB_pend_write == 1) begin
		do_pending_write(MEMWB_addr, MEMWB_value, MEMWB_size);
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
	ecalldone = myecalldone;
	WBEX_wbactive = mymemwb_wbactive;
end


endmodule

