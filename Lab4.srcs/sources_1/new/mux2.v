`timescale 1ns / 1ps


module mux2#(WIDTH = 32)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b, 
    input f, 
    output  reg [WIDTH-1:0] c 
    );
    
//    assign c = (f == 1'b0) ? a: b;

     always @(*) begin
         case(f)
             1'b0: c = a;
             1'b1: c = b;
             default: c = a;
         endcase
     end

endmodule
