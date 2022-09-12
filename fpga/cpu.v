module cpuTest (
    input wire rawclk,
    input wire [3:0] button,
    input wire [3:0] switch,
    output wire [7:0] nled,
    output wire [8:0] digit0data,
    output wire [8:0] digit1data,
    input wire rx,
    output wire tx
);  
    wire clk;
    assign clk = rawclk;
    // reg clk;
    // reg [31:0] counter;
    // initial counter = 32'b0;
    // initial clk = 1'b0;
    // always @(posedge rawclk ) begin
    //     if(counter == 120_000) begin
    //         counter <= 32'b0;
    //         clk = 1'b0;
    //     end
    //     else begin
    //         counter <= counter + 32'b1;
    //     end
    //     if(counter == 60_000) begin
    //         clk = 1'b1;
    //     end
    // end

    wire [7:0] digits;
    DigitDecoder digit0(
        .in(digits[7:4]),
        .out(digit0data)
    );
    DigitDecoder digit1(
        .in(digits[3:0]),
        .out(digit1data)
    );
    
    wire [7:0] led;
    assign nled = ~led;

    wire nrst;
    assign nrst = button[0];
    wire interrupt;
    // assign interrupt = button[1];


    wire devClk;
    wire devNrst;
    wire devClkEn;
    wire devWriteEn;
    wire [17:0] devAddr;
    wire [31:0] devData;
    wire [31:0] devQ;
    Serial serial(
        // mem interface
        .memNrst(devNrst),
        .memClk(devClk),
        .memClkEn(devClkEn),
        .memWE(devWriteEn),
        .memData(devData),
        .memAddr(devAddr),
        .memQ(devQ),
        // device io
        .rawClk(rawclk),     // 12MHz input
        .nrst(nrst),
        .rx(rx),
        .tx(tx),
        .rxInt(interrupt)
    );

    wire [31:0] cpuDebug;
    CPU cpu(
        .clk(clk),
        .nrst(nrst),
        .interrupt(interrupt),
        // device interface
        .devNrst(devNrst),
        .devClk(devClk),
        .devClkEn(devClkEn),
        .devWriteEn(devWriteEn),
        .devAddr(devAddr),
        .devData(devData),
        .devQ(devQ),
        // debug interface
        .debug(cpuDebug)
    );

    // debug outputs
    assign digits = 8'b0;
    assign led[7:0] = 8'b0;
    // assign led[0] = clk;
    // assign led[3:1] = 7'b0;
    // assign led[7:4] = cpuDebug[3:0];

endmodule






module CPU (
    input wire clk,
    input wire nrst,
    input wire interrupt,
    // device interface
    output wire devNrst,
    output wire devClk,
    output wire devClkEn,
    output wire devWriteEn,
    output wire [17:0] devAddr,
    output wire [31:0] devData,
    input wire [31:0] devQ,
    // debug interface
    output wire [31:0] debug
);
    // fist enable signal to start the cpu
    reg [31:0] initEnableCounter;
    reg initEnable;
    initial begin
        initEnableCounter = 32'b0;
        initEnable = 1'b0;
    end
    always @(negedge clk or negedge nrst) begin
        if(~nrst) begin
            initEnableCounter = 32'b0;
            initEnable = 1'b0;
        end
        else begin
            if(initEnable) begin
                initEnable = 1'b0;
            end
            if(initEnableCounter < 32'd4) begin
                initEnableCounter = initEnableCounter + 1;
            end
            if(initEnableCounter == 32'd3) begin
                initEnable = 1'b1;
            end
        end
    end

    wire fetchEnable;
    wire fetchCmdPush;
    wire [31:0] fetchCmdIn;
    wire [1:0] sysMode;
    wire immEn;
    wire [31:0] imm;
    wire fetchNextAlu;
    wire fetchNextWrite;
    wire fetchNextRead;
    wire pcpp;
    wire [2:0] aluOpCode;
    wire aluSub;
    wire cjmp;
    wire crjmp;
    wire [3:0] regIn1Addr;
    wire [3:0] regIn2Addr;
    wire [3:0] regOut1Addr;
    wire [3:0] regOut2Addr;
    Fetch fetch(
        .clk(clk),
        .nrst(nrst),
        .interrupt(interrupt),
        .enable(fetchEnable),
        .cmdPush(fetchCmdPush),
        .cmdIn(fetchCmdIn),
        .sysMode(sysMode),
        .immEn(immEn),
        .imm(imm),
        .nextAlu(fetchNextAlu),
        .nextWrite(fetchNextWrite),
        .nextRead(fetchNextRead),
        .pcpp(pcpp),
        .aluOpCode(aluOpCode),
        .aluSub(aluSub),
        .cjmp(cjmp),
        .crjmp(crjmp),
        .regIn1Addr(regIn1Addr),
        .regIn2Addr(regIn2Addr),
        .regOut1Addr(regOut1Addr),
        .regOut2Addr(regOut2Addr)
    );

    wire [31:0] regIn1;
    wire [31:0] regIn2;
    wire [31:0] regOut1;
    wire [31:0] regOut2;
    wire [31:0] pcOut;
    wire regPush;
    Registers registers(
        .in1(regIn1),
        .in2(regIn2),
        .out1(regOut1),
        .out2(regOut2),
        .pc(pcOut),
        .in1Addr(regIn1Addr),
        .in2Addr(regIn2Addr),
        .out1Addr(regOut1Addr),
        .out2Addr(regOut2Addr),
        .nrst(nrst),
        .push(regPush),
        .pcpp(pcpp)
    );

    wire [31:0] aluIn1;
    wire [31:0] aluIn2;
    wire [31:0] aluOut1;
    wire [31:0] aluOut2;
    wire [31:0] aluPcIn;
    wire aluPush;
    wire aluNext;
    ALU alu(
        // clock
        .clk(clk),
        .nrst(nrst),
        // sequence control
        .enable(fetchNextAlu),
        // data input
        .in1(aluIn1),
        .in2(aluIn2),
        .pc(aluPcIn),
        // function control ports
        .opCode(aluOpCode),
        .sub(aluSub),
        .cjmp(cjmp),
        .crjmp(crjmp),
        // data output
        .out1(aluOut1),
        .out2(aluOut2),
        .pushResult(aluPush),
        // sequence control
        .next(aluNext)
    );

    wire [31:0] memAddr;
    wire [31:0] memData;
    wire [31:0] memQ;
    wire memPush;
    wire memNext;
    MemController memController(
        // mem controller interface
        .clk(clk),
        .write(fetchNextWrite),
        .read(fetchNextRead),
        .nrst(nrst),
        .addr(memAddr),
        .data(memData),
        .Q(memQ),
        .pushOut(memPush),
        .next(memNext),
        // external device interface
        .devNrst(devNrst),
        .devClk(devClk),
        .devClkEn(devClkEn),
        .devWriteEn(devWriteEn),
        .devAddr(devAddr),
        .devData(devData),
        .devQ(devQ)
    );

    SysMux sysMux(
        .mode(sysMode),
        .immEn(immEn),
        
        // reg
        .regIn1(regIn1),
        .regIn2(regIn2),
        .regOut1(regOut1),
        .regOut2(regOut2),
        .regPc(pcOut),
        .regPush(regPush),
        // fetch
        .fetchIn(fetchCmdIn),
        .fetchImm(imm),
        .fetchPush(fetchCmdPush),
        // alu
        .aluOut1(aluOut1),
        .aluOut2(aluOut2),
        .aluIn1(aluIn1),
        .aluIn2(aluIn2),
        .aluPc(aluPcIn),
        .aluPush(aluPush),
        // mem
        .memQ(memQ),
        .memAddr(memAddr),
        .memData(memData),
        .memPush(memPush)
    );

    assign fetchEnable = initEnable | aluNext | memNext;

    // debug interface
    assign debug = pcOut;
    // assign debug = {5'b0,devWriteEn,devClkEn,devClk,devData[7:0],memData[7:0],pcOut[7:0]};

endmodule

