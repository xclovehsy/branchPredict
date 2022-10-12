`timescale 1ns / 1ps


module aludec(funct, aluop, alucontrol);
    input [5:0] funct;
    input [1:0] aluop;
    output reg [2:0] alucontrol;

    always @(*) begin
        case(aluop)
            2'b00: alucontrol = 3'b010;     // add
            2'b01: alucontrol = 3'b110;     // add
            2'b10: begin
                case(funct) 
                    6'b100_000: alucontrol = 3'b010;    // add
                    6'b100_010: alucontrol = 3'b110;    // subtract
                    6'b100_100: alucontrol = 3'b000;    // and
                    6'b100_101: alucontrol = 3'b001;    // or 
                    6'b101_010: alucontrol = 3'b111;    // slt
                    default: alucontrol = 3'b000;
                endcase
            end
            default: alucontrol = 3'b000;
        endcase
    end


endmodule
