`timescale 1ns / 1ps


module pc(clk, rst, en, clr, newpc, pc);
    input clk;              // 时钟
    input rst;              // 复位信号
    input en;              // 使能信号
    input clr;
    input [31:0] newpc;    // 更新的pc�?
    output reg [31:0]pc;    // pc

    initial pc = 32'h0;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pc <= 32'b0;
        end
        else if(clr) begin
        pc<=32'b0;
        end
        else if(en) begin
            pc <= newpc;
        end
    end



    
endmodule
