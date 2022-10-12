`timescale 1ns / 1ps


module hazard(
    input [4:0] RsE,RtE, RsD, RtD,
    input [4:0] WriteRegM, WriteRegW, WriteRegE,
    input RegWriteM, RegWriteW, RegWriteE,MemtoRegE,MemtoRegM, MemtoRegW,
    input BranchD, 

    output reg [1:0] ForwardAE, ForwardBE,
    output wire ForwardAD, ForwardBD,
    output StallF, StallD, FlushE
    );
    
    always@(RsE or RtE or WriteRegM or WriteRegW or RegWriteM or RegWriteW) begin
        ForwardAE=2'b00;
        ForwardBE=2'b00;
        if(RsE!=0) begin
            if(RsE==WriteRegM&&RegWriteM)
                ForwardAE=2'b10;
            else if(RsE==WriteRegW&&RegWriteW)
                ForwardAE=2'b01;
        end
        if(RtE!=0) begin
            if(RtE==WriteRegM&&RegWriteM)
                ForwardBE=2'b10;
            else if(RtE==WriteRegW&&RegWriteW)
                ForwardBE=2'b01;
        end
    end

    wire branchstall;
    assign branchstall = BranchD &  
                    (RegWriteE & 
                    (WriteRegE == RsD | WriteRegE == RtD) |
                    MemtoRegM &
                    (WriteRegM == RsD | WriteRegM == RtD));
                    
    assign ForwardAD = (RsD != 0 & RsD == WriteRegM & RegWriteM);
    assign ForwardBD = (RtD != 0 & RtD == WriteRegM & RegWriteM);
    
    wire lwstall;
    assign lwstall = MemtoRegE & (RtE == RsD | RtE == RtD);
    assign StallD = lwstall | branchstall;
    assign StallF = StallD;
    assign FlushE = StallD;
    


endmodule
