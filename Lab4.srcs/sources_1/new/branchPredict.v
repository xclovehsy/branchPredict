`timescale 1ns / 1ps

// ======================================================
// ========      基于全局历史的分支预�????      =============
// ======================================================
module branchPredict(
    input [31:0] PCPredict, // �?????要预测pc   
    input [31:0] PC,        // pc�?????
    input [31:0] PCBranch,  // branch pc�?????
    input [31:0] PCJump,    // jump pc�?????
    input rst,
    input preRe,            // 预测结果是否正确
    input branch,           // branch指令
    input jump,             // jump指令
    input branchPre,        // branch指令的预测结�?????
    input jumpPre,          // jump指令的预测结�?????
    input JumpOrBranchF,
    input P1M,
    input P2M,
    //-------
    output bp,           // 预测结果
    output clear,           // 清空流水线信�?????
    output reg [31:0] PCVal,    // 正确的pc�?????
    output selectPre,        // pc多路选择器信�?????
    output P1F,
    output P2F
    );

    // BHT (branch history table)
    reg [2:0] BHT[7:0];
    // BHT (global history register)
    reg [5:0] GHR;
    reg [5:0] ReGHR;
    // GPHT
    reg [1:0] GPHT[63:0];
    // LPHT
    reg [1:0] LPHT[63:0];
    // CPHT
    reg [1:0] CPHT;



    integer i;
    initial begin
        GHR = 6'b0;
        ReGHR = 6'b0;
        p1 = 1'b0;
        p2 = 1'b0;
        CPHT = 2'b01;
        PCVal = 32'b0;
        for(i = 0; i<8; i=i+1) begin
            BHT[i] <= 3'b0;
        end

        for(i = 0; i<64; i=i+1) begin
            LPHT[i] <= 2'b01;
        end

        for(i = 0; i<64; i=i+1) begin
            GPHT[i] <= 2'b01;
        end
    end

    // ======================================================
    // =============      获取全局分支预测结果      ===========
    // ======================================================

    // hash reflect
    wire[2:0] Ghash = PCPredict[5:0];

    // get GPHT index  通过异或的方式索引GPHT
    wire [5:0] idxGPHT = Ghash ^ GHR;

    // get counter Gvalue
    wire [1:0] Gvalue = GPHT[idxGPHT];

    // 根据饱和计数器结果获取预测结�??????????
    reg p1;
    always @(JumpOrBranchF) begin
        if (JumpOrBranchF) begin
            case(Gvalue)
                2'b00: p1 = 1'b0;
                2'b01: p1 = 1'b0;
                2'b10: p1 = 1'b1;
                2'b11: p1 = 1'b1;
                default: p1 = 1'b0;
            endcase

            // 并更新GHR的�??
            GHR = {GHR[4:0], p1};
        end
     end
     assign P1F = p1;

     // ======================================================
    // =============      获取�???部历史分支预测结�???      ========
    // ======================================================

     // hash reflect
    wire[2:0] Lhash = PCPredict[4:2];

    // get PHT index
    wire [5:0] idxLPHT = {BHT[Lhash], PCPredict[4:2]};

    // get counter value
    wire [1:0] Lvalue = LPHT[idxLPHT];

    // 根据饱和计数器结果获取预测结�?????????
    reg p2;
    always @(Lvalue) begin
         case(Lvalue)
             2'b00: p2 = 1'b0;
             2'b01: p2 = 1'b0;
             2'b10: p2 = 1'b1;
             2'b11: p2 = 1'b1;
             default: p2 = 1'b0;
         endcase
     end

    assign P2F = p2;

    // =============    根据CPHT选择bp      ===================
    assign bp = (CPHT[1] == 1'b1) ? p2: p1;


    // ======================================================
    // =============    更新GHR、GPHT      ===================
    // ======================================================
    
    reg [5:0] idxGPHTBack;
    wire [2:0] hashBack = PC[5:0];
    wire en = jump || branch;
    wire jumpReal = preRe ? jumpPre: ~jumpPre;
    wire branchReal = preRe ? branchPre: ~branchPre;
    wire realSig = jump ? jumpReal : (branch ? branchReal: 1'b0);
    always @(en) begin
        if(en) begin
            // 首先通过ReGHR修正GHR
            ReGHR = {ReGHR[4:0], realSig};
            
            if(ReGHR != GHR) begin
                GHR = ReGHR;
            end

            // 修改GPHT饱和计数器的�?????
            idxGPHTBack = hashBack ^ GHR;
            if(realSig && GPHT[idxGPHTBack] != 2'b11) begin
                GPHT[idxGPHTBack] = GPHT[idxGPHTBack] + 1;
            end
            else if(!realSig && GPHT[idxGPHTBack] != 2'b00) begin
                GPHT[idxGPHTBack] = GPHT[idxGPHTBack] - 1;
            end
        end
    end

    // ======================================================
    // =============    更新BHT、LPHT      ===================
    // ======================================================
    
    reg [5:0] idxLPHTBack;
    wire [2:0] hashBackL = PC[4:2];
    always @(en) begin
        if(en) begin
            // 修改PHT饱和计数器的�????
            idxLPHTBack = {BHT[hashBackL], PC[4:2]};
            if(realSig && LPHT[idxLPHTBack] != 2'b11) begin
                LPHT[idxLPHTBack] = LPHT[idxLPHTBack] + 1;
            end
            else if(!realSig && LPHT[idxLPHTBack] != 2'b00) begin
                LPHT[idxLPHTBack] = LPHT[idxLPHTBack] - 1;
            end

            // BHT表的更新
            BHT[hashBackL] = {BHT[hashBackL][1:0], realSig};
        end
    end


    // ======================================================
    // =============    修正CPHT      ===================
    // ======================================================
    wire p1r = P1M == realSig;
    wire p2r = P2M == realSig;
    always @(en) begin
        if(en) begin
            if({(P1M == realSig), (P2M == realSig)} == 2'b10 && CPHT != 2'b00) begin
                CPHT = CPHT -1;
            end
            else if({(P1M == realSig), (P2M == realSig)} == 2'b01 && CPHT != 2'b11) begin
                CPHT = CPHT +1;
            end
            else begin
                CPHT = CPHT;
            end
        end
    end


    // ======================================================
    // =============    错误结果修正      ===================
    // ======================================================

    // 清空流水线和将指令计数器置为正确的�??
    assign clear = en && !preRe;
    assign selectPre = clear;

    always @(en) begin
        if(en && !preRe) begin
            if(branch && !branchPre) begin
                PCVal = PCBranch;
            end
            else if (jump && !jumpPre) begin
                PCVal = PCJump;
            end 
            else begin
                PCVal = PC +  32'h4;
            end 
        end
    end


endmodule
