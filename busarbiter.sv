module busarbiter
(
	input icache_busreq,
	input dcache_busreq,
	input icache_busidle,
	input dcache_busidle,
	output icache_busgrant,
	output dcache_busgrant

);


always_comb begin
		if(icache_busidle == 1 && dcache_busidle == 1) begin
			if(dcache_busreq == 1) begin
				dcache_busgrant = 1;	
			end else if(icache_busreq == 1) begin
				icache_busgrant = 1;
			end
		end
		if(icache_busreq == 0) begin
			icache_busgrant =0;
		end
		if(dcache_busreq == 0) begin
			dcache_busgrant = 0;
		end
end
endmodule	
