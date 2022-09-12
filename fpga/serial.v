module Serial (
    // mem interface
    input wire memNrst,
    input wire memClk,
    input wire memClkEn,
    input wire memWE,
    input wire [31:0] memData,
    input wire [17:0] memAddr,
    output wire [31:0] memQ,
    // device io
    input wire rawClk,     // 12MHz input
    input wire nrst,
    input wire rx,
    output wire tx,
    output wire rxInt
);

    // interal tx clock ~9600Hz
    reg txClk;
    reg [11:0] txClkCnt;
    initial txClkCnt = 12'd0;
    initial txClk = 1'b0;
    always @(posedge rawClk or negedge nrst) begin
        if(~nrst) begin
            txClkCnt = 12'd0;
            txClk = 1'b0;
        end
        else begin
            if(txClkCnt == 12'd1250) begin
                txClkCnt = 12'd0;
                txClk = 1'b0;
            end
            else begin
                txClkCnt = txClkCnt + 12'b1;
            end
            if(txClkCnt == 12'd625) begin
                txClk = 1'b1;
            end
        end
    end

    // interal rx clock ~48000Hz
    reg rxClk;
    reg [7:0] rxClkCnt;
    initial rxClkCnt = 8'd0;
    initial rxClk = 1'b0;
    always @(posedge rawClk or negedge nrst) begin
        if(~nrst) begin
            rxClkCnt = 8'd0;
            rxClk = 1'b0;
        end
        else begin
            if(rxClkCnt == 8'd250) begin
                rxClkCnt = 8'd0;
                rxClk = 1'b0;
            end
            else begin
                rxClkCnt = rxClkCnt + 8'b1;
            end
            if(rxClkCnt == 8'd125) begin
                rxClk = 1'b1;
            end
        end
    end
    
    

    // tx logic

    wire [7:0] txFIFOOut;
    wire txFIFOWE;
    wire txFIFORE;
    wire txFIFOEmpty;
    wire txFIFOFull;
    wire txFIFOAlmostFull;
    wire txFIFOAlmostEmpty;
    serialFIFO txFIFO(
        .Data(memData[7:0]),
        .WrClock(memClk),
        .RdClock(txClk),
        .WrEn(txFIFOWE),
        .RdEn(txFIFORE),
        .Reset(~nrst),
        .RPReset(~nrst),
        .Q(txFIFOOut),
        .Empty(txFIFOEmpty),
        .Full(txFIFOFull),
        .AlmostEmpty(txFIFOAlmostEmpty),
        .AlmostFull(txFIFOAlmostFull)
    );

    assign txFIFOWE = memClkEn & memWE & (memAddr == 18'h0);

    reg [9:0] txSteps;
    reg [9:0] txBuffer;
    reg hasTxData;
    assign tx = txBuffer[0];
    initial begin
        txSteps = 10'b1;
        txBuffer = 10'b1_1111_1111_1;
        hasTxData = 1'b0;
    end
    assign txFIFORE = txSteps[1];

    // txSteps
    always @(negedge txClk or negedge nrst) begin
        if(~nrst) begin
            txSteps <= 10'b1;
        end
        else begin
            txSteps[9:1] <= txSteps[8:0];
            txSteps[0] <= txSteps[9];
        end
    end
    // hasTxData
    always @(posedge txSteps[1] or negedge nrst) begin
        if(~nrst) begin
            hasTxData = 1'b0;
        end
        else begin
            hasTxData = ~txFIFOEmpty;
        end
    end
    // txBuffer
    always @(posedge txClk or negedge nrst) begin
        if(~nrst) begin
            txBuffer <= 10'b1_1111_1111_1;
        end
        else if(txSteps[2]) begin
            if(hasTxData) begin
                txBuffer[0] = 1'b0;
                txBuffer[8:1] = txFIFOOut;
                txBuffer[9] = 1'b1;
            end
            else begin
                txBuffer = 10'b1_1111_1111_1;
            end
        end
        else begin
            txBuffer <= txBuffer >> 1;
        end
    end





    // rx logic

    wire [7:0] rxFIFOIn;
    wire [7:0] rxFIFOOut;
    wire rxFIFOWE;
    wire rxFIFORE;
    wire rxFIFOEmpty;
    wire rxFIFOFull;
    wire rxFIFOAlmostEmpty;
    wire rxFIFOAlmostFull;
    serialFIFO rxFIFO(
        .Data(rxFIFOIn),
        .WrClock(rxClk),
        .RdClock(memClk),
        .WrEn(rxFIFOWE),
        .RdEn(rxFIFORE),
        .Reset(~nrst),
        .RPReset(~nrst),
        .Q(rxFIFOOut),
        .Empty(rxFIFOEmpty),
        .Full(rxFIFOFull),
        .AlmostEmpty(rxFIFOAlmostEmpty),
        .AlmostFull(rxFIFOAlmostFull)
    );


    assign rxFIFORE = memClkEn & (~memWE) & (memAddr == 18'h1);

    reg [5:0] rxSteps;
    reg [44:0] rxSamples;
    initial begin
        rxSteps = 6'd0;
        rxSamples = 45'b0;
    end
    // rxSteps
    always @(negedge rxClk or negedge nrst) begin
        if(~nrst) begin
            rxSteps = 6'd0;
        end
        else begin
            if((~rx)&(rxSteps==6'd0)) begin
                rxSteps = 6'd1;
            end
            else if((rxSteps>6'd0) & (rxSteps<6'd48)) begin
                rxSteps = rxSteps + 6'd1;
            end
            else if(rxSteps == 6'd48) begin
                rxSteps = 6'd0;
            end
        end
    end
    // rxSamples
    always @(posedge rxClk or negedge nrst) begin
        if(~nrst) begin
            rxSamples <= 45'b0;
        end
        else if((rxSteps>6'd0) & (rxSteps<6'd46)) begin
            rxSamples[43:0] <= rxSamples[44:1];
            rxSamples[44] <= rx;
        end
    end
    // rxFIFOWE
    assign rxFIFOWE = (rxSteps == 6'd46);
    // rxFIFOIn
    assign rxFIFOIn[0] = rxSamples[7];
    assign rxFIFOIn[1] = rxSamples[12];
    assign rxFIFOIn[2] = rxSamples[17];
    assign rxFIFOIn[3] = rxSamples[22];
    assign rxFIFOIn[4] = rxSamples[27];
    assign rxFIFOIn[5] = rxSamples[32];
    assign rxFIFOIn[6] = rxSamples[37];
    assign rxFIFOIn[7] = rxSamples[42];

    // mem output
    /*
        Device address:
        0x0: txData     // write only
        0x1: rxData     // read only
        0x2: flags      // read only
        flags:
        (MSB)   rxFIFOEmpty, txFIFOAlmostFull, txFIFOFull (LSB)
    */
    wire [31:0] rxData;
    wire [31:0] flags;

    assign rxData[31:8] = 24'b0;
    assign rxData[7:0] = rxFIFOOut;

    assign flags[31:3] = 29'b0;
    assign flags[0] = txFIFOFull;
    assign flags[1] = txFIFOAlmostFull;
    assign flags[2] = rxFIFOEmpty;
    
    assign memQ = (memAddr == 18'h2) ? flags :
                (memAddr == 18'h1) ? rxData:
                32'b0;
    // interrupt
    assign rxInt = (~rxFIFOEmpty);

endmodule