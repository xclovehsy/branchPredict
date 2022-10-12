`timescale 1ns / 1ps

// 带有 enable、reset 与 clear 的触发

module flopenrc #( parameter WIDTH = 8) (
        input wire clk , rst , en , clear ,
        input wire [ WIDTH -1:0] d ,
        output reg [ WIDTH -1:0] q
    );

    always @( posedge clk or posedge rst) begin
        if( rst ) begin
            q <= 0;
        end else if( clear ) begin
            q <= 0;
        end else if( en ) begin
        /* code */
            q <= d ;
        end
    end
 endmodule
