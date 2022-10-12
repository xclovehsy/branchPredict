`timescale 1ns / 1ps

// 偶分频器 M = 1000_000 N = 500000   WIDTH = 17 为(N的位宽-1)
module clk_div #(parameter N=2, WIDTH=7)( 
    input clk, 
    input rst, 
    output reg clk_out 
    ); 

    reg [WIDTH:0]counter; 
    always @(posedge clk or posedge rst) begin 
        if (rst) begin 
            // reset 
            counter <= 0; 
        end 
        else if(counter == N-1)begin 
            counter <= 0; 
        end 
        else begin 
            counter <= counter + 1; 
        end 
    end 
    always @(posedge clk or posedge rst) begin 
        if (rst) begin // reset 
            clk_out <= 0; 
        end 
        else if (counter == N-1) begin 
            clk_out <= !clk_out; 
        end 
    end 
endmodule
