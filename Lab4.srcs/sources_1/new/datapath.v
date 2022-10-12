`timescale 1ns / 1ps


module datapath(
    input clk,          
    input rst,          
    input [31:0] instr,
    input [31:0] readdata,
    
    //---------------------------    
    output [31:0] aluout,    
    output [31:0] pc,           
    output [31:0] writedata,     
    output [31:0] memwrite
    );

    // 数据信号----------------------
    wire [31:0] PC_, PC_new, PCF, InstrD;
    wire [31:0] PCPlus4F, PCPlus4D, PCPlus4E;               
    wire [31:0] Rd1D, Rd2D, Rd1E, Rd2E;
    wire [4:0] RtE, RdE, RsE, RsD, RtD, RdD;
    wire [31:0] SignImmD, SignImmE;
    wire [31:0] SrcAE, SrcBE, WriteDataE,WriteDataM;
    wire [4:0] WriteRegE, WriteRegM, WriteRegW;
    wire [31:0] PCBranchE, PCBranchM, PCBranchD;
    wire [31:0] ALUOutE, ALUOutM, ALUOutW;
    wire ZeroE, ZeroM;
    wire [31:0] ReadDataW, ResultW;
    //-------------------------------

    // 控制信号-----------------------
    wire RegWriteD, RegWriteE, RegWriteM, RegWriteW;
    wire MemtoRegD, MemtoRegE, MemtoRegM, MemtoRegW;
    wire MemWriteD, MemWriteE, MemWriteM;
    wire BranchD, BranchE, BranchM;
    wire [2:0] ALUControlD, ALUControlE;
    wire ALUSrcD, ALUSrcE;
    wire RegDstD, RegDstE;
    wire PCSrcM, PCSrcD;
    wire JumpD;
    //-------------------

    // 竞争处理信号------------------
    wire [1:0]ForwardAE, ForwardBE;
    wire StallF, StallD, FlushE;
    wire ForwardAD, ForwardBD;
    //----------------------------------

    // 分支预测信号------------------
    wire BPF, BPD; // 预测跳转结果
    wire branchPreD, branchPreE, branchPreM;    // 根据预测以及branch判断的pc跳转命令
    wire jumpPreD, jumpPreE, jumpPreM;      
    wire PreReE,PreReM; // 预测结果正确与否
    wire [31:0] PCD, PCE, PCM; // 传�?�pc信号
    wire [31:0] PCJumpD, PCJumpE, PCJumpM;
    wire JumpE, JumpM;
    wire clearPre, selectPre;
    wire [31:0] PCVal, PC_new_pre;
    reg [8:0]sigPF;  // fetch阶段获取指令译码
    wire JumpOrBranchF;
    wire  P1F,P2F,P1D,P2D,P1E,P2E,P1M,P2M;
    //----------------------------------



    
    //信号连接-----------------------
    assign aluout = ALUOutM;
    assign pc = PCF;
    assign writedata = WriteDataM;
    assign memwrite = MemWriteM;

    assign RsD = InstrD[25:21];
    assign RtD = InstrD[20:16];
    assign RdD = InstrD[15:11];
    //--------------------------


    
    // *****************************************************
    // ********         竞争冒险模块           **************
    // *****************************************************
    hazard ha(
        .RsE(RsE),
        .RtE(RtE),
        .RsD(RsD),
        .RtD(RtD),
        .WriteRegM(WriteRegM),
        .WriteRegW(WriteRegW),
        .WriteRegE(WriteRegE), 
        .RegWriteM(RegWriteM), 
        .RegWriteW(RegWriteW),
        .RegWriteE(RegWriteE),
        .MemtoRegE(MemtoRegE), 
        .MemtoRegM(MemtoRegM),
        .MemtoRegW(MemtoRegW), 
        .BranchD(BranchD), 
        
        //----------
        .ForwardAE(ForwardAE), 
        .ForwardBE(ForwardBE),
        .ForwardAD(ForwardAD), 
        .ForwardBD(ForwardBD),  
        .StallF(StallF), 
        .StallD(StallD), 
        .FlushE(FlushE)
    );

    // *****************************************************
    // ********          分支预测模块           **************
    // *****************************************************
    branchPredict bp(
        .PCPredict(PCF),                    // �????要预测pc
        .rst(rst),   
        .bp(BPF),                           // 预测结果
        .preRe(PreReM),                     // 预测结果是否正确
        .branch(BranchM),                   // branch指令
        .jump(JumpM),                       // jump指令
        .PC(PCM),                           // pc�????
        .PCBranch(PCBranchM),               // branch pc�????
        .PCJump(PCJumpM),                    // jump pc�????
        .branchPre(branchPreM),                        // branch指令的预测结�????
        .jumpPre(jumpPreM),                          // jump指令的预测结�????
        .clear(clearPre),
        .PCVal(PCVal),
        .selectPre(selectPre),
        .JumpOrBranchF(JumpOrBranchF),
        .P1F(P1F),
        .P2F(P2F),
        .P1M(P1M),
        .P2M(P2M)
    );



    // =========================================================================
    // ===================              Fetch阶段            ===================
    // =========================================================================

    mux2 #(32) pc_mux1(.a(PCPlus4F), .b(PCBranchD), .f(branchPreD), .c(PC_));
    mux2 #(32) pc_mux2(.a(PC_), .b(PCJumpD), .f(jumpPreD), .c(PC_new));
    assign PCJumpD = {PCPlus4F[31:28], InstrD[25:0], 2'b00};

    // 分支预测模块
    mux2 #(32) pc_mux3(.a(PC_new), .b(PCVal), .f(selectPre), .c(PC_new_pre));
    pc p(
        .clk(clk), 
        .rst(rst),
        .clr(1'b0),
        .en(~StallF),
        .newpc(PC_new_pre), 
        .pc(PCF)
    );
    
    assign PCPlus4F = PCF + 32'h4;

    // 32+32
    flopenrc #(200) flop_D(
        .clk(clk), 
        .rst(rst), 
        .en(~StallD), 
        // .clear(PCSrcD),
        .clear(clearPre),
        .d({instr, PCPlus4F}), 
        .q({InstrD, PCPlus4D})
    ); 

    // 分支预测模块
    // 在预测阶段根�????? PC 值索�????? BHT，得到对应的 BHR，根�????? BHR 的内容索�????? PHT，得到对应的饱和计数器，然后根据饱和计数器的内容得到预测方向
    always @(instr) begin
        case(instr[31:26])
            6'b000_000: sigPF = 9'b01100_0010;     //R-type
            6'b100_011: sigPF = 9'b01010_0100;     //lw
            6'b101_011: sigPF = 9'b00010_1000;     //sw
            6'b000_100: sigPF = 9'b00001_0001;     //beq
            6'b001_000: sigPF = 9'b01010_0000;     //addi
            6'b000_010: sigPF = 9'b10000_0000;     //j
            default: sigPF = 9'b00000_0000;
        endcase
    end
    assign JumpOrBranchF = sigPF[4] || sigPF[8];

    flopenrc #(200) flop_D_bp(
        .clk(clk), 
        .rst(rst), 
        .en(~StallD), 
        // .clear(PCSrcD),
        .clear(clearPre),
        .d({BPF, PCF, P1F, P2F}), 
        .q({BPD, PCD, P1D, P2D}) 
    ); 

    // =========================================================================
    // ===================              decode阶段            ===================
    // =========================================================================

    // 控制竞争
    wire [31:0]t_rd1, t_rd2;
    mux2 rd1_mux(.a(Rd1D), .b(ALUOutM), .f(ForwardAD), .c(t_rd1));
    mux2 rd2_mux(.a(Rd2D), .b(ALUOutM), .f(ForwardBD), .c(t_rd2));

    assign PCSrcD = BranchD & (t_rd1 == t_rd2);
    
    controller c(
		.inst(InstrD),
		//------------------
		.regwrite(RegWriteD),
		.memtoreg(MemtoRegD),
		.memwrite(MemWriteD),
		.branch(BranchD),
		.alucontrol(ALUControlD),
		.alusrc(ALUSrcD),
		.regdst(RegDstD),
        .jump(JumpD)
	);

    regfile rf( 
        .clk(clk),
        .we3(RegWriteW), 
        .ra1(InstrD[25:21]), 
        .ra2(InstrD[20:16]), 
        .wa3(WriteRegW), 
        .wd3(ResultW),
        .rd1(Rd1D), 
        .rd2(Rd2D)
    );


    assign SignImmD = {{16{InstrD[15]}}, InstrD[15:0]};
    adder branch_add(.a({SignImmD[29:0], 2'b00}), .b(PCPlus4D), .y(PCBranchD));

    // (1+1+1+1+1+1+3)+(32+32+5+5+5+32) = 120
    flopenrc #(200) flop_E(
        .clk(clk), 
        .en(1'b1), 
        // .clear(FlushE), 
        .clear(clearPre),
        .rst(rst), 
        .d({RegWriteD,MemtoRegD,MemWriteD,BranchD,ALUControlD,ALUSrcD,RegDstD,Rd1D, Rd2D, InstrD[25:11], SignImmD}), 
        .q({RegWriteE,MemtoRegE,MemWriteE,BranchE,ALUControlE,ALUSrcE,RegDstE,Rd1E, Rd2E, RsE, RtE, RdE, SignImmE})    
    );

    // 分支预测模块
    assign branchPreD = BranchD & BPD; // 判断当前指令是否是分支指令，结合取指阶段得到的预测方向，判断是否跳转
    assign jumpPreD = JumpD & BPD;
    flopenrc #(200) flop_E_bp(
        .clk(clk), 
        .en(1'b1), 
        // .clear(FlushE), 
        .clear(clearPre),
        .rst(rst), 
        .d({branchPreD, jumpPreD, PCD, PCBranchD, PCJumpD, JumpD, BranchD, P1D,P2D}), 
        .q({branchPreE, jumpPreE, PCE, PCBranchE, PCJumpE, JumpE, BranchE, P1E,P2E})    
    );


    // =========================================================================
    // ===================              Execute阶段          ===================
    // =========================================================================

    alu #(32) alu(.A(SrcAE), .B(SrcBE), .F(ALUControlE), .result(ALUOutE));
    mux2 #(32) alu_mux(.a(WriteDataE), .b(SignImmE), .f(ALUSrcE), .c(SrcBE));
    mux2 #(5) reg_mux(.a(RtE), .b(RdE), .f(RegDstE), .c(WriteRegE));
    assign ZeroE = ALUOutE == 32'b0;

    //数据前推
    mux3 SrcAE_mux(.a(Rd1E), .b(ResultW), .c(ALUOutM), .f(ForwardAE), .y(SrcAE));
    mux3 SrcBE_mux(.a(Rd2E), .b(ResultW), .c(ALUOutM), .f(ForwardBE), .y(WriteDataE));

    // (1+1+1)+(32+32+5) = 72
    flopenrc #(200) flop_M(
        .clk(clk), 
        .rst(rst),
        .en(1'b1), 
        // .clear(1'b0),
        .clear(clearPre),
        .d({RegWriteE,MemtoRegE,MemWriteE, ALUOutE, WriteDataE,WriteRegE}), 
        .q({RegWriteM,MemtoRegM,MemWriteM, ALUOutM, WriteDataM, WriteRegM})
    );

    // 分支预测模块 判断预测结果是否正确
    assign PreReE = BranchE ? (ZeroE == branchPreE) :(JumpE ? (JumpE == jumpPreE): 1'b0);

    flopenrc #(200) flop_M_bp(
        .clk(clk), 
        .rst(rst),
        .en(1'b1), 
        // .clear(1'b0),
        .clear(clearPre),
        .d({PreReE, BranchE, JumpE, jumpPreE, branchPreE, PCE, PCBranchE, PCJumpE, ZeroE, P1E, P2E}), 
        .q({PreReM, BranchM, JumpM, jumpPreM, branchPreM, PCM, PCBranchM, PCJumpM, ZeroM, P1M, P2M})
    );


    // =========================================================================
    // ===================              Memory阶段          ===================
    // =========================================================================

    // (1+1)+(32+32+5) = 71
    flopenrc #(200) flop_W(
        .clk(clk), 
        .rst(rst), 
        .clear(1'b0),
        .en(1'b1),
        .d({RegWriteM,MemtoRegM,ALUOutM, readdata, WriteRegM}), 
        .q({RegWriteW,MemtoRegW,ALUOutW, ReadDataW, WriteRegW})
    );

    // =========================================================================
    // ===================              Writeback阶段          ===================
    // =========================================================================

    mux2 #(32) result_mux(.a(ALUOutW), .b(ReadDataW), .f(MemtoRegW), .c(ResultW));

    
endmodule