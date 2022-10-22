# branchPredict

[TOC]



## 1. 项目简介

**项目内容：**

1. 实现基于局部历史的分支指令方向预测。
2. 实现基于全局历史的分支指令方向预测。
3. 实现竞争的分支指令方向预测。



本次实验实现的分支预测功能基于上学期实现的五级流水线CPU。因此我在五级流水线CPU的基础上实现了branchPredict分支预测模块。本次实验我实现的是**竞争的分支指令方向预测**，CPU线路图如下图所示。

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/20221022161921.png)

 

## 2. 项目实现

### 2.1. 基于局部历史的分支预测功能实现

在基于局部分支预测中我所采用的是将pc值hash映射成3bit的数值进行BHT表的索引，因此BHT共有8个表项，每一项有3bit宽，记录PC值对应的3次分支历史。再将3bit宽的BHR值与PC的3bit的hash值进行拼接共6bit作为PHT的索引值。这里PHT是基于2位的饱和计数器，因此PHT位2bit宽共64项的寄存器。映射关系如下图所示。

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/20221022161948.png)

#### 2.1.1. fetch阶段

在此阶段中，分支预测模块将32bit的PC值3-5位作为hash值作为对BHT的索引，再与hash值进行拼接，索引LPHT得到对应的饱和计数器，然后根据饱和计数器的 内容得到预测方向。

~~~verilog
// ======================================================
// =============  获取基于局部历史分支预测结结果   ========
// ======================================================
// hash reflect
  wire[2:0] Lhash = PCPredict[4:2];
  // get PHT index
  wire [5:0] idxLPHT = {BHT[Lhash], PCPredict[4:2]};
  // get counter value
  wire [1:0] Lvalue = LPHT[idxLPHT];
  // 根据饱和计数器结果获取预测结果
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
~~~



####2.1.2. decode阶段

在译码阶段判断当前指令是否是分支指令，结合取指阶段得到的预测方向，判断是否跳转。由于在五级流水线中包含jump和branch两种跳转指令，因此需要判断当前指令是否两种指令之一。在datapath中实现的代码如下所示。

 ~~~verilog
// 分支预测模块
assign branchPreD = BranchD & BPD; 
// 判断当前指令是否是分支指令，结合取指阶段得到的预测方向，判断是否跳转
assign jumpPreD = JumpD & BPD;
 ~~~



#### 2.1.3. excute阶段

在此阶段中，datapath需要通过上一阶段传递参数对分支预测的结果判断是否正确，同时由于包含jump和branch两种指令，因此需要同时对两种指令的预测结果判断是否正确。在datapath中实现的代码如下所示。

 ~~~verilog
// 分支预测模块 判断预测结果是否正确
assign PreReE = BranchE ? (ZeroE == branchPreE) :(JumpE ? (JumpE == jumpPreE): 1'b0);
 ~~~



#### 2.1.4. memory阶段

在访存阶段，如果预测正确，则根据访存阶段的指令地址索引到对应的 BHR，将分支指令的跳转方向左移进得到的 BHR 中； 如果预测错误，则清空流水线和将指令计数器置为正确的值，除此之外还要将分支指令正确 的跳转方向左移进得到的 BHR 中。更新BHT以及LPHT的实现如下所示。

~~~verilog
// ======================================================
// =============  更新BHT、LPHT   ===================
// ======================================================

reg [5:0] idxLPHTBack;
  wire [2:0] hashBackL = PC[4:2];
  always @(en) begin
    if(en) begin
      // 修改PHT饱和计数器的值
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
~~~

当预测结果错误时，还需要对CPU进行修正，这里采用的方法是清空流水线并同时将pc置为正确的值。

 ~~~verilog
// 清空流水线和将指令计数器置为正确的值
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
        PCVal = PC + 32'h4;
      end 
    end
  end
 ~~~

同时在datapath的fetch阶段中添加一个多路选择器对当前的pc值进行选择，如果预测错误则修正指令计数器为正确的值。

 ~~~verilog
// 分支预测模块
 mux2 #(32) pc_mux3(.a(PC_new), .b(PCVal), .f(selectPre), .c(PC_new_pre));
 ~~~

**

### 2.2. 基于全局历史的分支预测功能实现

基于全局历史的分支预测功能与基于局部历史的分支预测功能的实现方法类似。这里只需要在上述功能实现的基础上添加一个GHR（global history register）用于记录所分支指令的跳转结果。每遇到一条分支指令时，将其执行结果右移入GHR中。这里所选择是6bit宽的GHR，也就是说可以记录全局6次分支指令的跳转方向结果。

 

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/20221022161956.png)

对于预测错误的修复所采用的是提交阶段修复法。在提交阶段放置一个 GHR（被称作 Retired GHR）。只有当分支指令进入到提交阶段时，才更新这个 GHR，如果在提交阶段发现分支预测错误，那么此时预测阶段的 GHR 的内容是错误的，此时我们就可以将 Retired GHR 内的值写入到预测阶段的 GHR 中。

 

#### 2.2.1. fetch阶段

在此阶段实现的方式是将pc的0-5位作为hash值，在与5位宽的GHR值进行异或得到的值作为GPHT的索引得到对应的饱和计数器，然后根据饱和计数器的内容得到预测方向。

~~~~verilog
// ======================================================
// =============   获取全局分支预测结果   ===========
// ======================================================

// hash reflect
  wire[5:0] Ghash = PCPredict[5:0];
  // get GPHT index 通过异或的方式索引GPHT
  wire [5:0] idxGPHT = Ghash ^ GHR;
  // get counter Gvalue
  wire [1:0] Gvalue = GPHT[idxGPHT];
  // 根据饱和计数器结果获取预测结值
  reg p1;
  always @(JumpOrBranchF) begin
​     if (JumpOrBranchF) begin
​      case(Gvalue)
​        2'b00: p1 = 1'b0;
​        2'b01: p1 = 1'b0;
​        2'b10: p1 = 1'b1;
​        2'b11: p1 = 1'b1;
​        default: p1 = 1'b0;
​      endcase
​       // 并更新GHR的值
​      GHR = {GHR[4:0], p1};
​    end
   end
   assign P1F = p1;
~~~~

decode、execute阶段对应关于datapath的判断是否跳转与判断预测结果是否正确功能与基于局部历史的分支预测功能实现原理相同。

 

#### 2.2.2. memory阶段

首先实现对GHR值的修正，基于从datapath得到的reGHR以及正确的跳转方向，获得正确的GHR值，若当前的GHR与正确值不同，则重新修正GHR的值，反之则不处理。其次需要对GPHT饱和计数器的值进行更新，当前指令为分支指令并且跳转，则GPHT饱和计数器值+1，若不跳转，则GPHR饱和计数器的值-1。

 ~~~verilog
// ======================================================
// =============  更新GHR、GPHT   ===================
// ======================================================

  reg [5:0] idxGPHTBack;
  wire [5:0] hashBack = PC[5:0];
  wire en = jump || branch;
  wire jumpReal = preRe ? jumpPre: ~jumpPre;
  wire branchReal = preRe ? branchPre: ~branchPre;
  wire realSig = jump ? jumpReal : (branch ? branchReal: 1'b0);
  always @(en) begin
​    if(en) begin
​      // 首先通过ReGHR修正GHR
​      ReGHR = {ReGHR[4:0], realSig};
​      if(ReGHR != GHR) begin
​        GHR = ReGHR;
​      end
​       // 修改GPHT饱和计数器的值
​      idxGPHTBack = hashBack ^ GHR;
​      if(realSig && GPHT[idxGPHTBack] != 2'b11) begin
​        GPHT[idxGPHTBack] = GPHT[idxGPHTBack] + 1;
​      end
​      else if(!realSig && GPHT[idxGPHTBack] != 2'b00) begin
​        GPHT[idxGPHTBack] = GPHT[idxGPHTBack] - 1;
​      end
​    end
end
 ~~~





 

### 2.3. 实现竞争的分支指令方向预测

基于局部历史的分支预测和基于全局历史的分支预测各有优缺点，对于不同特征的分支指令，它们预测的效果不同，因此需要根据分支指令的特征来选择预测方法。就像是两种预测方法在相互竞争一样。

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/20221022162003.png)

CPHT中的两位饱和计数器状态机如下图：

- 当P1预测正确，P2预测错误时，计数器减1；

- 当P1预测错误，P2预测正确时，计数器加1；
- 当P1、P2预测的结果一样时，不管对不对，计数器不变；

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/20221022162007.png)

当计数器位于饱和的00、01态时，使用P1预测；位于饱和的11、10态时，使用P2预测。所以，竞争的分支预测法其实是一种两级自适应算法，第一级预测分支指令的特征，第二级预测分支指令的方向。

 

#### 2.3.1. fetch阶段

在此阶段中branchPredict模块分别根据BHT、LPHT以及GHR、GPHT分别获取基于局部历史以及基于全局历史的分支预测结果，再根据CPHT的值进行选择。若CPHT的值为01或00，则选择基于全局历史的分支预测结果作为branchPredict的分支预测结果；若CPHT的值为11或10，则选择基于局部历史的分支预测结果作为branchPredict的分支预测结果。

 ~~~verilog
// =============  根据CPHT选择bp   ===================
assign bp = (CPHT[1] == 1'b1) ? p2: p1;
 ~~~



#### 2.3.2. memory阶段

在此阶段中的主要工作是对CPHT的值进行修正，如果基于局部历史的分支预测结果正确，且基于全局历史的分支预测结果错误，则CPHT的值+1。反之若基于全局历史的分支预测结果正确，基于局部历史的分支预测结果错误，则将CPHT的值-1。其余情况则不对CPHT的值进行修改

 ~~~verilog
// ======================================================
// =============  修正CPHT   ===================
// ======================================================

  wire p1r = P1M == realSig;
  wire p2r = P2M == realSig;
  always @(en) begin
​    if(en) begin
​      if({(P1M == realSig), (P2M == realSig)} == 2'b10 && CPHT != 2'b00) begin
​        CPHT = CPHT -1;
​      end
​      else if({(P1M == realSig), (P2M == realSig)} == 2'b01 && CPHT != 2'b11) begin
​        CPHT = CPHT +1;
​      end
​      else begin
​        CPHT = CPHT;
​      end
​    end
  end
 ~~~



## 3. 结果展示与分析

### 3.1 .指令计数器（PC）多路选择器的真值表

由于本次实验是在lab4五级流水线cpu的基础上所实现的，因此我在保留原本两个pc多路选择器的基础上，添加了一个多路选择器用于实现对分支预测结果错误的pc修正。三个多路选择器的线路布局如下图所示。

![6](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/6.png)

三个多路选择器可以合并为一个完整的多路选择器，其真值表如下所示：

| *selectPre* | *jumpPreD* | *branchPreD* | *Pc_new*  |
| ----------- | ---------- | ------------ | --------- |
| 1           | ×          | ×            | PCVal     |
| 0           | 1          | ×            | PCJumpD   |
| 0           | 0          | 1            | PCBranchD |
| 0           | 0          | 0            | PCPlus4F  |

 

### 3.2. 程序成功运行

该程序成功通过Lab04的测试程序，并打印“Simulation succeeded”。

 ![1](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/1.png)

 

### 3.3. 基于局部历史的分支预测结果分析

在本次实验中，BHT的表项初始值为0；PHT饱和计数器的值初始化为01。在测试文件中共有3条分支指令，第1条指令不跳转，第2、3条指令跳转，在仿真过程中可以看到三条跳转指令分别到达memory的时间分别为900ns、1200ns、2100ns。由下图可以看出在900ns并没有BHT表项值变化，说明程序可以正确识别第1条跳转指令不跳转。此外由于本实验所实现的hash映射比较简单（直接取pc3-5位作为hash值），导致第2、3条指令映射到同一BHT表项，但对其功能的正确运行没有影响。通过下图可以看出在1200ns、2100ns，程序正确识别到跳转指令并得到正确的执行结果，同时将其执行结果右移入对应的BHT表项中。

 ![2](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/2.png)

LPHT中对应的表项也分别在900ns、1200ns、2100ns进行了正确的更新。即第1条指令不跳转，饱和计数器数值-1；第2条指令跳转，对应饱和计数器+1；第3条指令跳转，对应饱和计数器数值+1。

![3](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/3.png)

因此结合以上分析，三条跳转指令对应的基于局部历史的分支预测结果应该分别为“不跳转”、“不跳转”、“不跳转”。这是由于饱和计数器的初始值为01、训练的指令数较少，因此不能准确的预测分支方向。

 

### 3.4. 基于全局历史的分支预测结果分析

这里将GHR的初始值设置为6个0，将GPHT饱和计数器的初始值设置为01。如下图所示jumporbanchF信号表示为fetch阶段的指令为branch或者jump指令。因此三条跳转指令到达fetch阶段的时间分别为600ns、900ns、1800ns。又由于饱和计数器的初始值为01且训练指令数较少，因此3条分支指令的基于全局历史的分支预测结果分别为“不跳转”、“不跳转”、“不跳转”，基于此我们可以观测下列仿真结果的正确性。

在600ns，第一条指令达到fetch阶段，预测“不跳转”，因此GHR右移一位“0”。当800ns第一条指令到达memory阶段时BranchPredict发现预测结果正确，不修改GHR；在900ns，第2条指令达到fetch阶段，预测“不跳转”，因此GHR右移一位“0”。当1100ns第2条指令到达memory阶段时BranchPredict发现此前预测结果错误，根据reGHR的值对GHR的值进行修正即将最低为修改为“1”；在1800ns，第3条指令达到fetch阶段，预测“不跳转”，因此GHR右移一位“0”。当2100ns第3条指令到达memory阶段时BranchPredict发现此前预测结果错误，根据reGHR的值对GHR的值进行修正即将最低为修改为“1”。

![4](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/4.png)

 

同时可以看到GPHT中对应的表项也分别在900ns、1200ns、2100ns进行了正确的更新。即第1条指令不跳转，饱和计数器数值-1；第2条指令跳转，对应饱和计数器+1；第3条指令跳转，对应饱和计数器数值+1。

![5](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/5.png)

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/clip_image012.png)

 

**（****4****）竞争的分支指令方向预测结果分析**

这里由于此前基于局部历史以及全局历史的PHT饱和计数器的初值均设置为01，使得这里仅有的三条指令均预测为“不跳转”。为了方便展示竞争的预测结果，这里将LPHT的值初始化为11，使得三条指令的基于局部历史的分支预测为“跳转”。

第一条跳转指令正确方向为“不跳转”，因此基于全局历史的分支预测结果正确，而基于局部历史的分支预测结果错误，CPHT的值-1；第二条跳转指令正确方向为“跳转”，因此基于局部历史的分支预测结果正确，而基于全局历史的分支预测结果错误，CPHT的值+1；第三条跳转指令正确方向为“跳转”，因此基于局部历史的分支预测结果正确，而基于全局历史的分支预测结果错误，CPHT的值+1；

![img](https://xc-figure.oss-cn-hangzhou.aliyuncs.com/img/clip_image014.png)

 