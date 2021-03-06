module decodeMod
(
input clk,
input reset,
input [31:0] IFID_instreg,
input [63:0] IFID_npc,
input IFID_ready,
input EXID_stall,
input EXIF_branch,
input ecalldone,
input icachenotstall,

output [63:0] IDEX_npc,
output [64:0] opcode,
output signed [63:0] rs1,
output signed [63:0] rs2,
output signed [5:0] rd,
output signed [19:0] immediate,
output IDEX_ready,
output [5:0] IDEX_rs1reg,
output [5:0] IDEX_rs2reg,
output IDIF_stall
//output signed [64:0] pcint
);

logic ecallstage;
logic ecallactive;
logic signed [11:0] temp;
logic signed [12:0] temp_addr;
logic signed [64:0] address;
logic signed [20:0] offset;
logic signed [11:0] sign12;
logic [31:0] instr_reg;
//logic X;



always_ff @(posedge clk) begin
	if (reset) begin
	end else begin
		if (IFID_ready == 0) begin
			IDEX_ready <= 0;
		end else begin
			IDEX_ready <=1;
		end
	end
end


always_ff @(posedge clk) begin
	if(reset) begin
		opcode = 0;
		rs1 = 0;
		rs2 = 0;
		rd = 0;
		immediate = 0;
	//	pcint = 0;
	end else begin
		if (ecallactive == 1 && icachenotstall == 1) begin
			instr_reg <= 32'h00000013;
			ecallstage <= 1;
		
		end else if (ecallstage == 1 && ecalldone == 0) begin
			ecallstage <= 1;
			instr_reg <= 32'h00000013;
		end else if (ecallstage == 1 && ecalldone == 1) begin
			ecallstage <= 0;
			if (IFID_ready == 1 && EXID_stall == 0) begin
                        	if(EXIF_branch == 1) begin
                                	instr_reg <=  32'h00000013;
                        	end else begin
                                	instr_reg <= IFID_instreg;
                        	end
                        	IDEX_npc <= IFID_npc;
                	end
                	else begin
                        	instr_reg <= instr_reg;
                        	IDEX_npc <= IDEX_npc;
              		end
		end else 
		if ( EXID_stall == 0 && icachenotstall == 1) begin
			if(EXIF_branch == 1) begin
				instr_reg <=  32'h00000013;
			end else begin
				instr_reg <= IFID_instreg;
			end
			IDEX_npc <= IFID_npc;
		//	IDEX_ready <= 1;
		end
		else begin
		//	IDEX_ready <= 0;
			instr_reg <= instr_reg;
			IDEX_npc <= IDEX_npc;
		end
	end
end

always_comb begin
	if(EXID_stall == 1 || ecallactive == 1 || (ecallstage == 1 && ecalldone == 0 )) begin
		IDIF_stall = 1;
	end else begin
		IDIF_stall = 0;
	end
end

always_comb begin
		 if(instr_reg == 8'h00) begin
                	//i_execute.printRegister;
			//$finish;
        	end;


               rs1 = regfile.gpr[instr_reg[19:15]];
               IDEX_rs1reg = instr_reg[19:15];
               rs2 = regfile.gpr[instr_reg[24:20]];
               IDEX_rs2reg = instr_reg[24:20];
               rd = instr_reg[11:7];
		ecallactive = 0;
		
	//	pcint = pc;
		if (instr_reg[6:0] == 7'b1101111) begin
			opcode = "jal";
			immediate = {instr_reg[31],instr_reg[19:12],instr_reg[20],instr_reg[30:21],1'b0};
			rd =instr_reg[11:7];
         	end else if (instr_reg[6:0] == 7'b0110111) begin
         		opcode = "lui";
			rd =instr_reg[11:7];
			immediate = instr_reg[31:12];
         	end else if (instr_reg[6:0] == 7'b0010111) begin
         		opcode = "auipc";
			rd =instr_reg[11:7];
			immediate = instr_reg[31:12];
         	end else if (instr_reg[6:0] == 7'b1100111) begin
			if({instr_reg[12],instr_reg[13],instr_reg[14]} == 3'b000) begin	
         			opcode = "jalr";
				rd =instr_reg[11:7];
				immediate = instr_reg[31:20];
				rs1 = regfile.gpr[instr_reg[19:15]];
			end else begin
					opcode = "retur";
				
			end 
		end else if (instr_reg[6:0] == 7'b0110011) begin
                	case({instr_reg[30], instr_reg[25], instr_reg[14:12]})
                        	5'b00000: opcode = "add";
                        	5'b10000: opcode = "sub";
             	         	5'b00001: opcode = "sll";
                	        5'b00010: opcode = "slt";
         	                5'b00011: opcode = "sltu";
                	        5'b00100: opcode = "xor";
                	        5'b10101: opcode = "sra";
                     	    	5'b00101: opcode = "srl";
                   	     	5'b00110: opcode = "or";
                        	5'b00111: opcode = "and";
                        	5'b01000: opcode = "mul";
                        	5'b01001: opcode = "mulh";
                        	5'b01010: opcode = "mulhsu";
                        	5'b01011: opcode = "mulhu";
                        	5'b01100: opcode = "div";
                        	5'b01101: opcode = "divu";
                        	5'b01110: opcode = "rem";
                        	5'b01111: opcode = "remu";
                	endcase
			rd =instr_reg[11:7];
			rs1 = regfile.gpr[instr_reg[19:15]];
			rs2 = regfile.gpr[instr_reg[24:20]];
			IDEX_rs1reg = instr_reg[19:15];
			IDEX_rs2reg = instr_reg[24:20];
			immediate = 0;
        	end else if (instr_reg[6:0] == 7'b0010011) begin
                	temp = instr_reg[31:20]; 
               	 	case(instr_reg[14:12])
                        	3'b000: opcode = "addi";
                        	3'b010: opcode = "slti";
                        	3'b011: opcode = "sltiu";
                        	3'b100: opcode = "xori";
                        	3'b110: opcode = "ori";
                        	3'b111: opcode = "andi";

                	endcase
                	case({instr_reg[30], instr_reg[14:12]})
                        	4'b0001: opcode = "slli";
                        	4'b0101: opcode = "srli";
                        	4'b1101: opcode = "srai";
                	endcase

			rd = instr_reg[11:7];
			rs1 = regfile.gpr[instr_reg[19:15]];
			rs2 = 0;
			IDEX_rs1reg = instr_reg[19:15];
                        IDEX_rs2reg = 0;

			immediate = temp;
        	end else if (instr_reg[6:0] == 7'b0000011) begin
                	temp = instr_reg[31:20];
                	case (instr_reg[14:12])
                        	3'b000: opcode = "lb";
                        	3'b001: opcode = "lh";
                        	3'b010: opcode = "lw";
                        	3'b100: opcode = "lbu";
                        	3'b101: opcode = "lhu";
				3'b011: opcode = "ld";
				3'b110: opcode = "lwu";
                	endcase
                	rd = instr_reg[11:7];
                	rs1 = regfile.gpr[instr_reg[19:15]];
                	rs2 = 0;
                        IDEX_rs1reg = instr_reg[19:15];
                        IDEX_rs2reg = 0;
               	 	immediate = temp;
       		end else if (instr_reg[6:0] == 7'b1100011) begin
                	//address = pcint + temp_addr;
                	case (instr_reg[14:12])
                        	3'b000: opcode = "beq";
                        	3'b001: opcode = "bne";
                        	3'b100: opcode = "blt";
                        	3'b101: opcode = "bge";
                        	3'b110: opcode = "bltu";
                        	3'b111: opcode = "bgeu";
               		endcase
			rd = 0;
                        rs1 = regfile.gpr[instr_reg[19:15]];
                        rs2 = regfile.gpr[instr_reg[24:20]];
                        IDEX_rs1reg = instr_reg[19:15];
                        IDEX_rs2reg = instr_reg[24:20];
			immediate = $signed({instr_reg[31],instr_reg[7],instr_reg[30:25],instr_reg[11:8],1'b0});
			//$display("bge setting immediate =%d",immediate);
        	end else if (instr_reg[6:0]  == 7'b0100011) begin
                	temp = {instr_reg[31:25],instr_reg[11:7]}; 
			case (instr_reg[14:12])
                        	3'b000: opcode = "sb";
                        	3'b001: opcode = "sh";
                        	3'b010: opcode = "sw";
                        	3'b011: opcode = "sd";
                	endcase
                	rd = 0;
                	rs1 = regfile.gpr[instr_reg[19:15]];
                	rs2 = regfile.gpr[instr_reg[24:20]];
                        IDEX_rs1reg = instr_reg[19:15];
                        IDEX_rs2reg = instr_reg[24:20];
                	immediate = temp;
         	end else if (instr_reg[6:0] == 7'b0111011) begin
                	case({instr_reg[30],instr_reg[25], instr_reg[14:12]})
                        	5'b00000: opcode = "addw";
                       		5'b10000: opcode = "subw";
                       	 	5'b00001: opcode = "sllw";
                        	5'b00101: opcode = "srlw";
                        	5'b10101: opcode = "sraw";
                        	5'b01000: opcode = "mulw";
                        	5'b01100: opcode = "divw";
                        	5'b01101: opcode = "divuw";
                        	5'b01110: opcode = "remw";
                        	5'b01111: opcode = "remuw";
               	 	endcase
			rd = instr_reg[11:7];
			rs1 = regfile.gpr[instr_reg[19:15]];
			rs2 = regfile.gpr[instr_reg[24:20]];
                        IDEX_rs1reg = instr_reg[19:15];
                        IDEX_rs2reg = instr_reg[24:20];
			immediate = 0;
        	end else if (instr_reg[6:0] == 7'b0011011) begin
                	temp = instr_reg[31:20]; 
                	case(instr_reg[14:12])
                        	3'b000: opcode = "addiw";
                	endcase
                	case({instr_reg[30], instr_reg[14:12]})
                        	4'b0001: opcode = "slliw";
                        	4'b0101: opcode = "srliw";
                        	4'b1101: opcode = "sraiw";
                	endcase
                	rd = instr_reg[11:7];
                	rs1 = regfile.gpr[instr_reg[19:15]];
                	rs2 = 0;
                        IDEX_rs1reg = instr_reg[19:15];
                        IDEX_rs2reg = 0;
                	immediate = temp;
        	end else if (instr_reg[31:0] == 32'b1110011) begin
			opcode = "ecall";
			ecallactive = 1;

        	end else if (instr_reg[6:0] == 7'b1110011) begin
               		case(instr_reg[14:12])
                       		3'b001: opcode = "csrrw";
                       		3'b010: opcode = "csrrs";
                       		3'b011: opcode = "csrrc";
               		endcase
        	end else if (instr_reg[6:0] == 7'b1110011) begin
               		case(instr_reg[14:12])
		       		3'b001: opcode = "csrrw";
                       		3'b001: opcode = "csrrw";
                       		3'b001: opcode = "csrrw";
               		endcase
        	end else begin
                	//case (instr_reg[6:0])
                       		//7'b0110111: begin
                		//	rd = instr_reg[11:7];
             			//	rs1 = 0;
                		//	rs2 = 0;
                		//	immediate = temp;
                       		//end
                       		//7'b0010111:  begin
                			//rd = instr_reg[11:7];
                			//rs1 = 0;
                			//rs2 = 0;
                			//immediate = temp;
                       		//end
                       		//7'b1101111: begin
                       			offset[20:0] = {instr_reg[31],instr_reg[19:12],instr_reg[20],instr_reg[30:21],1'b0};
                       		//	address = pcint + offset;
                       		//end
                       		//7'b1100111: begin
					opcode = "retur";
                           	//	temp = instr_reg[31:20];
                       		//end
             		//endcase
		
        	end
//	$display("%s, %b, %d, %d, %d,%d, ", opcode,instr_reg, rs1, rs2,rd, immediate);
     end

endmodule
