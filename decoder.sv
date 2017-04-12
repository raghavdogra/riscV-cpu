`include "getreg.sv"
module decoder();
getreg gr_name();
executer alu();

task decode;
input [31:0] lower;
input [63:0] pc;
logic [32:0] rd,rs1,rs2;
logic [64:0] opcode;
logic signed [11:0] temp;
logic signed [12:0] temp_addr;
logic signed [64:0] address;
logic signed [64:0] pcint;
logic signed [20:0] offset;
begin
pcint = pc;
         if(lower[31:0] == 31'h00000000) begin 
         	alu.printRegister;
	end;	
         if (lower[6:0] == 7'b0110011) begin
                gr_name.convert(lower[11:7],rd);
                gr_name.convert(lower[19:15],rs1);
                gr_name.convert(lower[24:20],rs2);
                case({lower[30], lower[25], lower[14:12]})
                        5'b00000: opcode = "add";
                        5'b10000: opcode = "sub";
                        5'b00001: opcode = "sll";
                        5'b00010: opcode = "slt";
                        5'b00110: opcode = "sltu";
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
                alu.execute(opcode,lower[11:7],lower[19:15],lower[24:20],0,pcint);
              //  $display ("%0x:  %x	%0s	%0s,%0s,%0s", pc, lower,opcode,rd,rs1,rs2);
        end else if (lower[6:0] == 7'b0010011) begin
                gr_name.convert(lower[11:7],rd);
                gr_name.convert(lower[19:15],rs1);
                temp = lower[31:20]; 
                case(lower[14:12])
                        3'b000: opcode = "addi";
                        3'b010: opcode = "slti";
                        3'b011: opcode = "sltiu";
                        3'b100: opcode = "xori";
                        3'b110: opcode = "ori";
                        3'b111: opcode = "andi";

                endcase
                case({lower[30], lower[14:12]})
                        4'b0001: opcode = "slli";
                        4'b0101: opcode = "srli";
                        4'b1101: opcode = "srai";
                endcase
                alu.execute(opcode,lower[11:7],lower[19:15],0,temp,pcint);

              /*  if (opcode == "addi") begin
                    if (temp == 0) begin
                       opcode = "mv";
                       if (rs1 == "zero") begin
                          if (rd == "zero") begin
                      		 $display("%0x:  %x	%0s", pc, lower,"nop");
                          end else
                      		 $display("%0x:  %x	%0s	%0s,0", pc, lower,"li",rd);
                       end else
                                 $display("%0x:  %x	%0s	%0s,%0s", pc, lower,opcode,rd,rs1);
                    end else if (rs1 == "zero") begin
                       opcode = "li";
                       $display("%0x:  %x	%0s	%0s,%0d", pc, lower,opcode,rd,temp);
                    end else
                       $display("%0x:  %x	%0s	%0s,%0s,%0d", pc, lower,opcode,rd,rs1,temp);
                end  else if (opcode == "slli" | opcode == "srli" | opcode == "srai" )
                       $display("%0x:  %x	%0s	%0s,%0s,0x%0x", pc, lower,opcode,rd,rs1,temp);
                else 
                       $display("%0x:  %x	%0s	%0s,%0s,%0d", pc, lower,opcode,rd,rs1,temp);*/
        end else if (lower[6:0] == 7'b0000011) begin
                gr_name.convert(lower[11:7],rd);
                gr_name.convert(lower[19:15],rs1);
                temp = lower[31:20];
                case (lower[14:12])
                        3'b000: opcode = "lb";
                        3'b001: opcode = "lh";
                        3'b010: opcode = "lw";
                        3'b100: opcode = "lbu";
                        3'b101: opcode = "lhu";
			3'b011: opcode = "ld";
			3'b110: opcode = "lwu";
                endcase
                alu.execute(opcode,lower[11:7],lower[19:15],0,temp,pcint);

              //  $display ("%0x:  %x	%0s	%0s,%0d(%0s)", pc , lower,opcode,rd,temp,rs1);
        end else if (lower[6:0] == 7'b1100011) begin
                gr_name.convert(lower[24:20],rs2);
                gr_name.convert(lower[19:15],rs1);
                temp_addr = {lower[31],lower[7],lower[30:25],lower[11:8],1'b0}; 
                address = pcint + temp_addr;
                case (lower[14:12])
                        3'b000: opcode = "beq";
                        3'b001: opcode = "bne";
                        3'b100: opcode = "blt";
                        3'b101: opcode = "bge";
                        3'b110: opcode = "bltu";
                        3'b111: opcode = "bgeu";
               endcase
              // alu.execute(opcode,0,lower[19:15],lower[24:20],0);

//                $display ("%0x:  %x	%0s	%0s,%0s,0x%0x", pc , lower,opcode,rs1,rs2,address);
        end else if (lower[6:0]  == 7'b0100011) begin
                gr_name.convert(lower[19:15],rs1);
                gr_name.convert(lower[24:20],rs2);
                temp = {lower[31:25],lower[11:7]}; 
		case (lower[14:12])
                        3'b000: opcode = "sb";
                        3'b001: opcode = "sh";
                        3'b010: opcode = "sw";
                        3'b011: opcode = "sd";
                endcase
                alu.execute(opcode,0,lower[19:15],lower[24:20],temp,pcint);

              //  $display ("%0x:  %x	%0s	%0s,%0d(%0s)", pc, lower,opcode,rs2,temp,rs1);

         end else if (lower[6:0] == 7'b0111011) begin
                gr_name.convert(lower[11:7],rd);
                gr_name.convert(lower[19:15],rs1);
                gr_name.convert(lower[24:20],rs2);
                case({lower[30],lower[25], lower[14:12]})
                        5'b00000: opcode = "addw";
                        5'b10000: opcode = "subw";
                        5'b00001: opcode = "sllw";
                        5'b00101: opcode = "srlw";
                        5'b10101: opcode = "sraw";
                        5'b01000: opcode = "mulw";
                        5'b01100: opcode = "divw";
                        5'b01101: opcode = "divwu";
                        5'b01110: opcode = "remw";
                        5'b01111: opcode = "remuw";
                endcase
              alu.execute(opcode,lower[11:7],lower[19:15],lower[24:20],0,pcint);

//                $display ("%0x:  %x	%0s	%0s,%0s,%0s", pc, lower,opcode,rd,rs1,rs2);
        end else if (lower[6:0] == 7'b0011011) begin
                gr_name.convert(lower[11:7],rd);
                gr_name.convert(lower[19:15],rs1);
                temp = lower[31:20]; 
                case(lower[14:12])
                        3'b000: opcode = "addiw";
                endcase
                case({lower[30], lower[14:12]})
                        4'b0001: opcode = "slliw";
                        4'b0101: opcode = "srliw";
                        4'b1101: opcode = "sraiw";
                endcase
                // if (opcode == "slliw" | opcode == "srliw" | opcode == "sraiw" )
                   alu.execute(opcode,lower[11:7],lower[19:15],0,temp,pcint);

               //        $display("%0x:  %x	%0s	%0s,%0s,0x%0x", pc, lower,opcode,rd,rs1,temp);
               // else 
                 //      $display("%0x:  %x	%0s	%0s,%0s,%0d", pc, lower,opcode,rd,rs1,temp);
        end else if (lower[6:0] == 7'b1110011) begin
                gr_name.convert(lower[11:7],rd);
                gr_name.convert(lower[19:15],rs1);
               case(lower[14:12])
                       3'b001: opcode = "csrrw";
                       3'b010: opcode = "csrrs";
                       3'b011: opcode = "csrrc";
               endcase
             // alu.execute(opcode,lower[11:7],lower[19:15],0,0);

               // $display ("%0x:	%x	%0s	%0s,csr,%0s", pc , lower,opcode,rd,rs1);
		       
        end else if (lower[6:0] == 7'b1110011) begin
                gr_name.convert(lower[11:7],rd);
               case(lower[14:12])
		       3'b001: opcode = "csrrw";
                       3'b001: opcode = "csrrw";
                       3'b001: opcode = "csrrw";
               endcase
            //  alu.execute(opcode,lower[11:7],0,0,lower[19:15]);

         /*       $display ("%0x:	%x	%0s	%0s,csr,%0d", pc , lower,opcode,rd,lower[19:15]);
        end else if (lower[31:0] == 32'b00000000000000000000000001110011) begin
		$display ("ecall");
        end else if (lower[31:0] == 32'b00000000000100000000000001110011) begin
		$display ("ebreak");
        end else if (lower[31:0] == 32'b00000000000000000001000000001111) begin
		$display ("fence.i");
        end else if (lower[31:0] == 32'b0000xxxxxxxx00000000000000001111) begin
		$display ("fence");
        end else if (lower[31:0] == 32'h00000000) begin */
        end 
              else begin
                case (lower[6:0])
                       7'b0110111: begin
                       gr_name.convert(lower[11:7],rd);
                       alu.execute("lui",lower[11:7],0,0,lower[31:12],pcint);
                      // $display("%0x:  %x	%0s	%0s,0x%0x",pc,lower,"lui",rd,lower[31:12]);
                       end
                       7'b0010111:  begin
                       gr_name.convert(lower[11:7],rd);
                       alu.execute("auipc",lower[11:7],0,0,lower[31:12],pcint);
                      // alu.execute(opcode,lower[11:7],lower[19:15],lower[24:20],0);
                      // $display("%0x:  %x	%0s	%0s,0x%0x",pc,lower,"auipc",rd,lower[31:12]);
                       end
                       7'b1101111: begin
                       gr_name.convert(lower[11:7],rd);
                       offset[20:0] = {lower[31],lower[19:12],lower[20],lower[30:21],1'b0};
                       address = pcint + offset;
                      //  alu.execute("jal",lower[11:7],0,0,address,pcint);
                      // $display ("%0x:  %x	%0s	%0s,0x%0x", pc , lower,"jal",rd,address);
                       end
                       7'b1100111: begin
                           gr_name.convert(lower[11:7],rd);
                           gr_name.convert(lower[19:15],rs1);
                           temp = lower[31:20];
                      //  alu.execute("jalr",lower[11:7],lower[19:15],0,lower[31:12],pcint);
                      // $display ("%0x:  %x	%0s	%0s,%0s,%0d", pc , lower,"jalr",rd,rs1,temp);
                       end
                       default: $display("");
             endcase
        end
     end
    endtask
endmodule

