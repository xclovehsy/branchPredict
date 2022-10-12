`timescale 1ns / 1ps


module controller(
        input [31:0] inst,
        //--------------------
        output regwrite,    
        output memtoreg,   
        output memwrite, 
        output branch,   
        output [2:0] alucontrol,
        output alusrc,
        output regdst,
        // input zero,
        output jump         
        // output pcsrc
    );

    wire [1:0] aluop;
    // wire jump;
    // wire branch;
    // assign pcsrc = zero & branch;
    

    maindec main_control(
        .op(inst[31:26]), 
        .control_sig({jump, regwrite, regdst, alusrc, branch, memwrite, memtoreg, aluop})    
    );

    aludec alu_dec(
        .funct(inst[5:0]),
        .aluop(aluop),
        .alucontrol(alucontrol)
    );
    
endmodule