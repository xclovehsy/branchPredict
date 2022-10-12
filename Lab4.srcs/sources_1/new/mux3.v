`timescale 1ns / 1ps

module mux3#(WIDTH = 32)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b, 
    input [WIDTH-1:0] c,
    input [1:0]f, 
    output reg [WIDTH-1:0] y 
    );

    always @(*) begin
        case (f)
            2'b00: y = a; 
            2'b01: y = b; 
            2'b10: y = c; 
            default: y = a;
        endcase
    end
    
endmodule
