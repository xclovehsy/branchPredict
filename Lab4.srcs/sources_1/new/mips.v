`timescale 1ns / 1ps


module mips(
	input wire clk,rst,
	output wire[31:0] pc,
	input wire[31:0] instr,
	output wire memwrite,
	output wire[31:0] aluout,writedata,
	input wire[31:0] readdata,

	// 仿真观察信号
	output wire memtoreg,alusrc,regdst,regwrite,jump,pcsrc,zero,
	output wire [2:0] alucontrol,
	output [31:0] result, 
	output wire [31:0] InstrD
    );
	
//	wire memtoreg,alusrc,regdst,regwrite,jump,pcsrc,zero; //,overflow;
//	wire[2:0] alucontrol;

	
	wire RegWriteD,MemtoRegD,MemWriteD,BranchD,ALUSrcD,RegDstD;
	wire [1:0] ALUControlD;

	controller c(
		.inst(InstrD),
		//------------------
		.regwrite(RegWriteD),
		.memtoreg(MemtoRegD),
		.memwrite(MemWriteD),
		.branch(BranchD),
		.alucontrol(ALUControlD),
		.alusrc(ALUSrcD),
		.regdst(RegDstD)
	);

	datapath dp(
		.clk(clk),
		.rst(rst),
		.instr(instr),
		.readdata(readdata),
		
		.regwrite(RegWriteD),
		.memtoreg(MemtoRegD),
		.memwrite(MemWriteD),
		.branch(BranchD),
		.alucontrol(ALUControlD),
		.alusrc(ALUSrcD),
		.regdst(RegDstD),
		//-------------------------
		.pc(pc),
		.aluout(aluout),
		.writedata(writedata),
		.result(result),
		.InstrD(InstrD), 
		.memwrite_(memwrite)
	);
	
endmodule
