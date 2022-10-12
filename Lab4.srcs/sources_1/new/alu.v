`timescale 1ns / 1ps


module alu #(parameter WIDTH = 32)(
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input [2:0] F,
    output  reg [WIDTH-1:0] result
    
    );
    
    always @(*) begin
        case (F)
            3'b010: result <= A + B;
            3'b110: result <= A - B;
            3'b000: result <= A & B;
            3'b001: result <= A | B;
            // 3'b100: result <= ~A;
            3'b111: result <= (A < B) ? 1: 0;
            default: result <= 0;
        endcase
    end
    
endmodule
