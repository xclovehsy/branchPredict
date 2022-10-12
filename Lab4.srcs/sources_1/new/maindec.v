`timescale 1ns / 1ps


module maindec(op, control_sig);
    input [5:0] op;  // instruction的高6位op
    output reg [8:0] control_sig;
    
    always @(*) begin
        case(op)
            6'b000_000: control_sig = 9'b01100_0010;     //R-type
            6'b100_011: control_sig = 9'b01010_0100;     //lw
            6'b101_011: control_sig = 9'b00010_1000;     //sw
            6'b000_100: control_sig = 9'b00001_0001;     //beq
            6'b001_000: control_sig = 9'b01010_0000;     //addi
            6'b000_010: control_sig = 9'b10000_0000;     //j
            default: control_sig = 9'b00000_0000;
        endcase
    end

endmodule
