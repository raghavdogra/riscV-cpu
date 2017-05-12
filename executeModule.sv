`include "getreg.sv"


module executeMod
(
    input clk,
    input reset,
    input [64:0] next_opcode,
    input [5:0] next_rd,
    input signed [63:0] next_rs1,
    input signed [63:0] next_rs2,
    input signed [19:0] next_immediate,
    input [64:0] next_IDEX_npc,
    input [5:0] next_rs1reg,
    input [5:0] next_rs2reg,
    input [5:0] MEMEX_rd,
    input [5:0] WBEX_rd,
    input [63:0] WBEX_rdval,
    input [63:0] MEMEX_rdval,
    input MEMEX_stall,
    input MEMEX_wbactive,
    input WBEX_wbactive,
    input IDEX_ready,
    output signed [63:0] exmm_aluresult,
    output signed [63:0] EXMEM_rs2,
    output [5:0] dest_reg,
    output branch,
    output [63:0] target_pc,
    output mem_active,
    output [7:0] ldst_size,
    output ldst_unsign,
    output load,
    output EXMEM_ready,
    output EXMEM_wbactive,
    output EXMEM_ecall,
    output EXID_stall
);

getreg gr_name();
    logic signed [63:0] abs;
    logic signed [63:0] abs1;
    logic signed [63:0] temp;
    logic [63:0] temp1;
    logic [127:0] unsign128;
    logic signed [127:0] sign128;
    logic signed [31:0] sign32 [3:0];


    logic [64:0] opcode;
    logic [5:0] rd;
    logic signed [63:0] rs1;
    logic signed [63:0] rs2;
    logic signed [19:0] immediate;
    logic [64:0] IDEX_npc;

    logic EX_stall;
    logic waitonecycle;
    logic onecycledone;
    logic waitonecyclecopy;

    logic rs1forward;
    logic rs2forward;

    logic [64:0] tempopcode;
    logic [5:0] temprd;
    logic signed [63:0] temprs1;
    logic signed [63:0] temprs2;
    logic signed [19:0] tempimmediate;
    logic [63:0] tempIDEX_npc;


    logic signed [63:0] pcint;

    logic bt;
    int x;
    logic [32:0] name;
   // output [4*8:0] name;
   
 always_ff @(posedge clk) begin
    if (reset) begin
    end
    else if(IDEX_ready == 1) begin
        EXMEM_ready <= 1;
    end else begin
        EXMEM_ready <= 0;
    end
end


always_ff @(posedge clk) begin
	if(waitonecycle == 1) begin
		onecycledone <= 1;
	end else begin
		onecycledone <= 0;
	end
end

//always_comb begin
//        if (EXMEM_rs2 == 64'h000000003fbffff5 && mem_active == 1 && load == 0) begin
 //               $display("BADDDDDDD EXMEM_rs2  opcode %s ", opcode);

   //     end
//end

always_comb begin
if (MEMEX_stall == 0) begin
	if (onecycledone == 1) begin
			waitonecycle = 0;
			EX_stall = 0;
				if(next_rs1reg == MEMEX_rd && MEMEX_wbactive == 1) begin
                temprs1 = MEMEX_rdval;
                EX_stall = 0;
                rs1forward = 0;
                waitonecycle = 0;
	        end else if(next_rs1reg == WBEX_rd && WBEX_wbactive == 1)begin
        	        temprs1 = WBEX_rdval;
               		 rs1forward = 1;
               		 EX_stall = 0;
           		   waitonecycle = 0;
       		 end else begin
                	temprs1 = next_rs1;
               		 EX_stall = 0;
             		   rs1forward = 1;
              		  waitonecycle = 0;
      		  end


	end else if(dest_reg == next_rs1reg && EXMEM_wbactive == 1 && load == 1) begin
                //stall
		EX_stall = 1;
		waitonecycle = 1;
		waitonecyclecopy = 1;
        end else if(dest_reg == next_rs1reg && EXMEM_wbactive == 1) begin
                temprs1 = exmm_aluresult;
                rs1forward = 1;
		EX_stall = 0;
		waitonecycle = 0;
        end else if(next_rs1reg == MEMEX_rd && MEMEX_wbactive == 1) begin
                temprs1 = MEMEX_rdval;
		EX_stall = 0;
                rs1forward = 0;
		waitonecycle = 0;
        end else if(next_rs1reg == WBEX_rd && WBEX_wbactive == 1)begin
                temprs1 = WBEX_rdval;
                rs1forward = 1;
		EX_stall = 0;
		waitonecycle = 0;
        end else begin
                temprs1 = next_rs1;
		EX_stall = 0;
                rs1forward = 1;
		waitonecycle = 0;
        end

	if (onecycledone == 1) begin
			waitonecycle = 0;
			EX_stall = 0;
		if(next_rs2reg == MEMEX_rd && MEMEX_wbactive == 1) begin
                temprs2 = MEMEX_rdval;
                rs2forward = 1;
   		     end else if(next_rs2reg == WBEX_rd && WBEX_wbactive == 1) begin
   	             temprs2 = WBEX_rdval;
    	            rs2forward = 1;
      		  end else begin
      	          temprs2 = next_rs2;
      	          rs2forward = 1;
       		 end

        end else if (dest_reg == next_rs2reg && EXMEM_wbactive == 1 && load == 1) begin
		EX_stall = 1;
		waitonecycle = 1;
		waitonecyclecopy = 1;

	
        end else if (dest_reg == next_rs2reg && EXMEM_wbactive == 1) begin
                temprs2 = exmm_aluresult;
                rs2forward = 1;
        end else if(next_rs2reg == MEMEX_rd && MEMEX_wbactive == 1) begin
                temprs2 = MEMEX_rdval;
                rs2forward = 1;
        end else if(next_rs2reg == WBEX_rd && WBEX_wbactive == 1) begin
                temprs2 = WBEX_rdval;
                rs2forward = 1;
        end else begin
                temprs2 = next_rs2;
                rs2forward = 1;
        end
end
end
     

   always_ff @(posedge clk) begin
        if (reset) begin
        end
        else begin
                //  exmm_aluresult = immediate;
                regfile.gpr[0] <= 0;
                if(IDEX_ready == 1 && EXID_stall == 0) begin
                        if(branch == 0) begin
                                opcode <= next_opcode;
                                immediate <= next_immediate;
                                rs1 <= temprs1;
                                rs2 <= temprs2;
                                IDEX_npc <= next_IDEX_npc;
                                rd <= next_rd;
        			if (temprs2 == 64'h000000003fbffff5 && next_opcode == "sw") begin
                			$display("BADDDDDDD EXMEM_rs2   ");
                			$display("dest_reg   %x", dest_reg);
                			$display("next_rs2reg   %x", next_rs2reg);
                			$display("MEMEX_rd %x  MEMEX_rdval %x", MEMEX_rd, MEMEX_rdval);
                			$display("WBEX_rd  %x    WBEX_rdval  %x ", WBEX_rd, WBEX_rdval);
                			$display("prev opcode  %s   ",opcode);
					
        			end
                        end else begin
                                opcode <= "addi";
                                rs1 <= 0;
                                rs2 <= 0;
                                rd <= 0;
                                immediate <=0;
                                IDEX_npc <= next_IDEX_npc;
                        end
                end else begin
                        opcode <= opcode;
                        rd <= rd;
                        rs1 <= rs1;
                        rs2 <= rs2;
                        immediate <= immediate;
                        IDEX_npc <= IDEX_npc;
                end
      end
   end


 
always_comb begin
		EXID_stall = (MEMEX_stall || EX_stall);
end

always_comb begin
	dest_reg = rd;
	branch = 0;
	mem_active = 0;
	load = 0;
	EXMEM_wbactive = 1;
	EXMEM_rs2 = rs2;
	EXMEM_ecall = 0;
	ldst_size = 0;
	ldst_unsign = 0;
	pcint = IDEX_npc;
	case(opcode)	
	    	"ecall": begin
		      	EXMEM_ecall = 1;
			end
	    	"lb": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 8;
			ldst_unsign = 0;
		      end
                "lh": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 16;
			ldst_unsign = 0;
		      end
                "lw": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 32;
			ldst_unsign = 0;
		      end
                "lbu": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 8;
			ldst_unsign = 1;
		       end
                "lhu": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 16;
			ldst_unsign = 1;
                       end
	    	"ld": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 64;
			ldst_unsign = 0;
                      end
		"lwu": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			load = 1;
			ldst_size = 32;
			ldst_unsign = 1;
		       end
		"sb": begin
			mem_active = 1;
			EXMEM_wbactive = 0;
			ldst_size = 8;
		      end
                "sh": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			EXMEM_wbactive = 0;
			ldst_size = 16;
		      end
                "sw": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			EXMEM_wbactive = 0;
			ldst_size = 32;
			$display("SWWW setting exmemaluresult =%d %x   (rs1 + immediate ) (%x(hex) %d)",exmm_aluresult,exmm_aluresult, rs1, immediate);
		      end
                "sd": begin
			exmm_aluresult = rs1 + immediate;
			mem_active = 1;
			EXMEM_wbactive = 0;
			ldst_size = 64;
		      end
		"blt": begin
			EXMEM_wbactive = 0;
				if(rs1 < rs2) begin
					branch = 1;
					target_pc = pcint + immediate;
				end else begin
					branch = 0;
				end
			end	
		"bltu": begin
			EXMEM_wbactive = 0;
			getAbs(rs1,abs);
			getAbs(rs2,abs1);
				if(abs < abs1) begin
					branch = 1;
					target_pc = pcint + immediate;
				end else begin
					branch = 0;
				end
			end	
		"bge": begin
			EXMEM_wbactive = 0;
				if(rs1 >= rs2) begin
					branch = 1;
					target_pc = pcint + immediate;
				end else begin
					branch = 0;
				end
			$display("BGE setting targetpc =%d (IDEXnpc + immediate ) (%x(hex) %d)",target_pc, pcint, immediate);
			end	
		"bgeu": begin
			EXMEM_wbactive = 0;
			getAbs(rs1,abs);
			getAbs(rs2,abs1);
				if(abs >= abs1) begin
					branch = 1;
					target_pc = pcint + immediate;
				end else begin
					branch = 0;
				end
			end	
		"beq": begin
			EXMEM_wbactive = 0;
				if(rs1 == rs2) begin
					branch = 1;
					target_pc = pcint + immediate;
				end else begin
					branch = 0;
				end
			end	
		"bne": begin
			EXMEM_wbactive = 0;
				if(rs1 != rs2) begin
					branch = 1;
					target_pc = IDEX_npc + immediate;
				end else begin
					branch = 0;
				end
			end	
		"add": begin
			exmm_aluresult = rs1 + rs2;
			end
		"addw": begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] + sign32[1];
                        exmm_aluresult = sign32[2];
			end
		"xor": begin
			exmm_aluresult = rs1 ^ rs2;
			end
		"or": begin
			exmm_aluresult = rs1 | rs2;
			end
		"and": begin
			exmm_aluresult = rs1 & rs2;
			end
		"addi": begin
			exmm_aluresult = rs1 + immediate;
			end
		"addiw": begin
                        sign32[0] = rs1 + immediate;
                        exmm_aluresult = sign32[0];
			end
		"sub": begin
			exmm_aluresult = rs1 - rs2;
			end
		"subw": begin
                        sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] - sign32[1];
                        exmm_aluresult = sign32[2];
			end
		"slti": begin
			if (rs1 < immediate)
				exmm_aluresult = 1;
			else
				exmm_aluresult = 0;
			end
                "sltiu": begin
			getAbs(rs1,abs);
			getAbs(immediate,abs1);
                        if (abs < abs1)
                                exmm_aluresult = 1;
                        else
                                exmm_aluresult = 0;
                        end

                "slt": begin
                        if (rs1 < rs2)
                                exmm_aluresult = 1;
                        else
                                exmm_aluresult = 0;
                        end
                "sltu": begin
                        getAbs(rs1,abs);
                        getAbs(rs2,abs1);
                        if (abs < abs1)
                                exmm_aluresult = 1;
                        else
                                exmm_aluresult = 0;
                        end
     
		"andi": begin
			exmm_aluresult = rs1 & immediate;
			end
		"xori": begin
			exmm_aluresult = rs1 ^ immediate;
			end
		"ori": begin
			exmm_aluresult = rs1 | immediate;
			end
  		"lui": begin
			exmm_aluresult = {immediate,3'h000};
                        end
		"auipc": begin
			temp = {immediate,3'h000};
                        exmm_aluresult = pcint + temp;
                        end
 		"jal": begin 
			branch = 1;
			target_pc = pcint + immediate;
			exmm_aluresult = pcint + 4;
			end
		"jalr": begin
			branch = 1;
			temp = rs1 + immediate;
			temp[0] = 0;
 			target_pc = temp;
			exmm_aluresult = pcint + 4;
                	end
		"slli": begin
			exmm_aluresult = rs1 << immediate[4:0];
			end
		"srli": begin
			exmm_aluresult = rs1 >> immediate[4:0];
			end
		"srai": begin
			temp = rs1;
			bt = temp[63];
			x = immediate[4:0];
			temp = temp >> immediate[4:0];
 			for (int i=63; i > (63-x); i--) begin
					temp[i] = bt;
				end
			exmm_aluresult = temp;
			end
		"slliw": begin
                        sign32[0] = rs1;
                        sign32[1] = sign32[0] << immediate[4:0];
                        exmm_aluresult = sign32[1];
                        end
                "srliw": begin
                        sign32[0] = rs1;
                        sign32[1] = sign32[0] >> immediate[4:0];
                        exmm_aluresult = sign32[1];
                        end
                "sraiw": begin
                        sign32[0] = rs1;
                        bt = sign32[0][31];
			x = immediate[4:0];
                        sign32[1] = sign32[0] >> immediate[4:0];
                        for (int i=31; i > (31-x); i--) begin
                       			 sign32[1][i] = bt;
                       	 	end
                        exmm_aluresult = sign32[1];
			end
               "sll": begin
                        exmm_aluresult = rs1 << rs2[5:0];
                        end
                "srl": begin
                        exmm_aluresult = rs1 >> rs2[5:0];
                        end
                "sra": begin
                        temp = rs1;
                        bt = temp[63];
			x = rs2[5:0];
			temp1 = rs2;
                        temp = temp >> temp1[5:0];
                        for (int i=63; i > (63-x); i--) begin
                                        temp[i] = bt;
                                end
                        exmm_aluresult = temp;
                        end
                "sllw": begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] << sign32[1][4:0];
                        exmm_aluresult = sign32[2];
                        end
                "srlw": begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] >> sign32[1][4:0];
                        exmm_aluresult = sign32[2];
                      //  exmm_aluresult = rs1 >> rs2;
                        end
                "sraw": begin
                        sign32[0] = rs1;
                        bt = sign32[0][31];
			sign32[1] = rs2;
			x = sign32[1][4:0];
                        sign32[2] = sign32[0] >> sign32[1][4:0];
                        for (int i=31; i > (31-x); i--) begin
                                         sign32[2][i] = bt;
                                end
                        exmm_aluresult = sign32[2];
                        end
		"rem":  begin
                        exmm_aluresult = rs1 % rs2;
                        end
                "remu": begin
                        getAbs(rs1, abs);
                        getAbs(rs2, abs1);
                        exmm_aluresult = abs % abs1;
                        end
                "remw":  begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] % sign32[1];
                        exmm_aluresult = sign32[2];
                        end
                "remuw": begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        getAbs(sign32[0], abs);
                        getAbs(sign32[1], abs1);
			sign32[2] = abs % abs1;
                        exmm_aluresult = sign32[2];
                        end
                "div":  begin
                        exmm_aluresult = rs1 / rs2;
                        end
                "divu": begin
                        getAbs(rs1, abs);
                        getAbs(rs2, abs1);
                        exmm_aluresult = abs / abs1;
                        end
                "divw":  begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] / sign32[1];
                        exmm_aluresult = sign32[2];
                        end
                "divuw": begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        getAbs(sign32[0], abs);
                        getAbs(sign32[1], abs1);
			sign32[2] = abs / abs1;
                        exmm_aluresult = sign32[2];
                        end
		"mul":	 exmm_aluresult = rs1 * rs2;
		"mulw": begin
			sign32[0] = rs1;
                        sign32[1] = rs2;
                        sign32[2] = sign32[0] * sign32[1];
                        exmm_aluresult = sign32[2];
			end
		"mulh": begin
			sign128 = rs1 * rs2;
			exmm_aluresult = sign128[127:64];
			end
		"mulhsu":begin
                         getAbs(rs2, abs1);
                         sign128 = rs1 * abs1;
                         exmm_aluresult = sign128[127:64];
			end
		"mulhu": begin
			 getAbs(rs1, abs);
                         getAbs(rs2, abs1);
			 unsign128 = abs * abs1;
			 exmm_aluresult = unsign128[127:64];
			 end
//		default: begin
//			$display("not add or mv");
//		end
	endcase
     end
   //    for (int i=0; i<=31; i++) begin
     //   $display ("%0d",regfile.gpr[i] );
     //  end 
    //  $display ("%0s,%0x,%0x,%0x, %0d",opcode,rd,rs1,rs2, immediate);
   
 
//	gr_name.convert(rd,name);
//        $display ("%0s\t%0s\t => %0d",opcode,name,exmm_aluresult);


 task printRegister;
logic [32:0] name;
 //    exmm_aluresult = immediate;
       for (int i=0; i<=31; i++) begin
        gr_name.convert(i,name);
	$display ("%0s	%x	%0d",name,regfile.gpr[i],regfile.gpr[i]);
       end
  endtask;

task getAbs;
	input [63:0] signd;
	output [63:0] abs;

	if(signd[63] == 1) 
		abs = -signd;
	else if(signd[63] == 0)
		abs = signd;
endtask;

endmodule

