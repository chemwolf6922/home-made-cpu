module Fetch (
    input wire clk,
    input wire nrst,
    input wire interrupt,
    input wire enable,
    input wire cmdPush,
    input wire [31:0] cmdIn,
    output reg [1:0] sysMode,
    output wire immEn,
    output wire [31:0] imm,
    output reg nextAlu,
    output reg nextWrite,
    output reg nextRead,
    output wire pcpp,
    output wire [2:0] aluOpCode,
    output wire aluSub,
    output wire cjmp,
    output wire crjmp,
    output wire [3:0] regIn1Addr,
    output wire [3:0] regIn2Addr,
    output wire [3:0] regOut1Addr,
    output wire [3:0] regOut2Addr
);
    reg state;
    reg step;
    reg interrupted;
    reg clearInterrupt;
    reg [31:0] cmdBuf;
    reg [31:0] cmd;
    reg pcppMusk;

    assign pcpp = pcppMusk & enable;
    
    wire [4:0] opCode;
    assign opCode = cmd[28:24];
    wire [2:0] immMode;
    assign immMode = cmd[31:29];
    
    wire opNextAlu;
    wire opNextWrite;
    wire opNextRead;

    // op code
    MUX16 #(.BITS(9)) decoder(
        .addr(opCode[3:0]),
        .in0  (9'b000_0_00_100),    // ADD
        .in1  (9'b000_1_00_100),    // SUB
        .in2  (9'b001_0_00_100),    // CLZ
        .in3  (9'b010_0_00_100),    // LS
        .in4  (9'b011_0_00_100),    // AND
        .in5  (9'b100_0_00_100),    // OR
        .in6  (9'b101_0_00_100),    // NOT
        .in7  (9'b110_0_00_100),    // XOR
        .in8  (9'b111_0_00_100),    // EQ
        .in9  (9'b000_0_10_100),    // CJMP
        .in10 (9'b000_0_11_100),    // CRJMP
        .in11 (9'b000_0_00_010),    // STROE
        .in12 (9'b000_0_00_001),    // LOAD
        .in13 (9'b000_0_00_100),    // (ADD)
        .in14 (9'b000_0_00_100),    // (ADD)
        .in15 (9'b000_0_00_100),    // (ADD)
        .out({aluOpCode,aluSub,cjmp,crjmp,opNextAlu,opNextWrite,opNextRead})    
    );
    
    // reg addr
    assign regOut1Addr = (immMode==3'b000)?cmd[11:8]:4'd0;
    assign regIn2Addr = (immMode>3'b010)?4'd0:cmd[15:12];
    assign regOut2Addr = (immMode>3'b100)?cmd[23:20]:
                        (immMode>3'b010)?4'd0:
                        cmd[19:16];
    assign regIn1Addr = cjmp?4'd14:     // cjmp aluOut1 = regIn1 = R14
                        (immMode>3'b100)?4'd0:cmd[23:20];
    // imm
    assign imm[11:0] = cmd[11:0];
    assign imm[15:12] = (immMode>3'b001)?cmd[15:12]:{(4){imm[11]}};
    assign imm[19:16] = (immMode>3'b010)?cmd[19:16]:{(4){imm[15]}};
    assign imm[31:20] = ((immMode==3'b110)|(immMode==3'b100))?12'b0:{(12){imm[19]}};
    assign immEn = ~(immMode==3'b000);

    initial begin
        sysMode = 2'b00;
        state = 1'b0;
        cmdBuf = 32'b0;
        cmd = 32'b0;
        nextAlu = 1'b0;
        nextWrite = 1'b0;
        nextRead = 1'b0;
        interrupted = 1'b0;
        clearInterrupt = 1'b0;
        pcppMusk = 1'b0;
        step = 1'b0;
    end

    // state & sysMode & cmd & clearInterrupt & pcppMusk
    always @(posedge clk or negedge nrst) begin
        if(~nrst) begin
            state = 1'b0;
            sysMode = 2'b00;
            cmd = 32'b0;
            clearInterrupt = 1'b0;
            pcppMusk = 1'b0;
        end
        else begin
            if(enable) begin
                step = 1'b1;
                if(~state) begin
                    if(~interrupted) begin
                        state = 1'b1;
                        sysMode = 2'b10;
                        if(~cjmp) begin
                            pcppMusk = 1'b1;
                        end
                    end
                    else begin
                        // handle interrupt
                        clearInterrupt = 1'b1;
                        cmd = 32'hC9_0_00002;  // CJMP r0 0b0000_0000_0000_0000_0001
                        sysMode = 2'b00;
                    end
                end
                else begin
                    state = 1'b0;
                    cmd = cmdBuf;
                    if((cmd[28:24]==5'd11)|(cmd[28:24]==5'd12)) begin   // store or load
                        sysMode = 2'b01;
                    end
                    else begin
                        sysMode = 2'b00;
                    end
                end
            end
            else begin
                if(clearInterrupt) begin
                    clearInterrupt = 1'b0;        
                end
                if(pcppMusk) begin
                    pcppMusk = 1'b0;
                end
                if(step) begin
                    step = 1'b0;
                end
            end
        end
    end
    // interrupted
    always @(posedge interrupt or posedge clearInterrupt or negedge nrst) begin
        if(~nrst) begin
            interrupted = 1'b0;
        end
        else if(clearInterrupt) begin
            interrupted = 1'b0;
        end
        else begin
            interrupted = 1'b1;
        end
    end
    // cmdBuf
    always @(posedge cmdPush  or negedge nrst) begin
        if(~nrst) begin
            cmdBuf = 32'b0;
        end
        else begin
            cmdBuf = cmdIn;
        end
    end
    // nextAlu & nextWrite & nextRead
    always @(negedge clk or negedge nrst) begin
        if(~nrst) begin
            nextAlu = 1'b0;
            nextWrite = 1'b0;
            nextRead = 1'b0;
        end
        else begin
            if(step) begin
                if(sysMode == 2'b10) begin
                    nextRead = 1'b1;
                end
                else begin
                    if(opNextAlu) begin
                        nextAlu = 1'b1;
                    end
                    if(opNextWrite) begin
                        nextWrite = 1'b1;
                    end
                    if(opNextRead) begin
                        nextRead = 1'b1;
                    end
                end
            end
            else begin
                if(nextAlu) begin
                    nextAlu = 1'b0;
                end
                if(nextWrite) begin
                    nextWrite = 1'b0;
                end
                if(nextRead) begin
                    nextRead = 1'b0;
                end
            end
        end
    end


endmodule
