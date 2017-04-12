module getreg();

  task convert;

    input [5:0] register;
    output [4*8:0] name;
    begin
      case(register)
        0: name = "zero";
        1: name = "ra";
        2: name = "sp";
        3: name = "gp";
        4: name = "tp";
        5: name = "t0";
        6: name = "t1";
        7: name = "t2";
        8: name = "s0";
        9: name = "s1";
       10: name = "a0";
       11: name = "a1";
       12: name = "a2";
       13: name = "a3";
       14: name = "a4";
       15: name = "a5";
       16: name = "a6";
       17: name = "a7";
       18: name = "s2";
       19: name = "s3";
       20: name = "s4";
       21: name = "s5";
       22: name = "s6";
       23: name = "s7";
       24: name = "s8";
       25: name = "s9";
       26: name = "s10";
       27: name = "s11";
       28: name = "t3";
       29: name = "t4";
       30: name = "t5";
       31: name = "t6";
      endcase
    end
  endtask
endmodule
  

