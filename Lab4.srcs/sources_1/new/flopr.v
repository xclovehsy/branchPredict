`timescale 1ns / 1ps


// 带有 reset 的触发器
module flopr #( parameter WIDTH = 8) (
        input wire clk , rst ,
        input wire [ WIDTH -1:0] d ,
        output reg [ WIDTH -1:0] q
    );

    always @( posedge clk , posedge rst ) begin
        if( rst ) begin
            q <= 0;
        end else begin
            q <= d ;
        end
    end
endmodule
