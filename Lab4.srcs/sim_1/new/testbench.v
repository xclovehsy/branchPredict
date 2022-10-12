`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 13:54:42
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench();
	reg clk;
	reg rst;

	wire[31:0] writedata,dataadr;
	wire [31:0] pc, instr;
	wire memwrite;
	wire [31:0] readdata;

	// top dut(clk,rst,writedata,dataadr,memwrite);

	top dut(
		.clk(clk),
		.rst(rst),
		.writedata(writedata),
		.dataadr(dataadr),
		.memwrite(memwrite),
		.pc(pc),
		.instr(instr),
		.readdata(readdata)
	);
	


// input wire clk,rst,
// 	output wire[31:0] writedata,dataadr,
// 	output wire memwrite,
// 	output [31:0] pc, instr,
	
// 	output wire memtoreg,alusrc,regdst,regwrite,jump,pcsrc,zero,
// 	output wire [2:0] alucontrol,
// 	output wire [31:0] result,
// 	output wire [31:0] readdata

	initial begin 
	   clk = 1'b0;
	   rst = 1'b1;
	   #20 rst = 1'b0;
	end
	
    always #5 clk = ~clk;
//	always begin
//		clk <= 1;
//		#10;
//		clk <= 0;
//		#10;
	
//	end

	always @(negedge clk) begin
		if(memwrite) begin
			/* code */
			if(dataadr === 84 & writedata === 7) begin
				/* code */
				$display("Simulation succeeded");
				$stop;  
			end else if(dataadr !== 80) begin
				/* code */
				$display("Simulation Failed");
				$stop;
			end
		end
	end
endmodule
