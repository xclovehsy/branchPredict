`timescale 1ns / 1ps


module top(
	input wire clk,rst,
	output wire[31:0] writedata,dataadr,
	output wire memwrite,
	output [31:0] pc, instr,
	output wire [31:0] readdata 
    );

	// 分频
  	wire lclk;
	clk_div #(5, 5) div(.clk(clk), .rst(rst), .clk_out(lclk));

	// mips mips(lclk,rst,pc,instr,memwrite,dataadr,writedata,readdata, //memtoreg,alusrc,regdst,regwrite,jump,pcsrc,zero,alucontrol, result, InstrD);
	
	datapath dp(
		.clk(lclk),
		.rst(rst),
		.instr(instr),
		.readdata(readdata),

		//-------------------------
		.aluout(dataadr),
		.pc(pc),
		.writedata(writedata),
		.memwrite(memwrite)
	);


	
	//-----------------
	inst_mem imem(
		.clka(clk),
		.ena(1'b1), 
		.addra(pc/4), 
		.douta(instr)
	);

	data_mem dmem(
		.clka(clk),
		.ena(1'b1), 
		.wea(memwrite),
		.addra(dataadr),
		.dina(writedata),
		.douta(readdata)
	);

endmodule
