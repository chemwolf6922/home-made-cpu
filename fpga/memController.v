module MemController (
    // mem controller interface
    input wire clk,
    input wire write,
    input wire read,
    input wire nrst,
    input wire [31:0] addr,
    input wire [31:0] data,
    output wire [31:0] Q,
    output wire pushOut,
    output reg next,
    // external device interface
    output wire devNrst,
    output wire devClk,
    output wire devClkEn,
    output wire devWriteEn,
    output wire [17:0] devAddr,
    output wire [31:0] devData,
    input wire [31:0] devQ
);
    wire clkEn;
    wire writeEn;
    wire rst;
    assign clkEn = read | write;
    assign writeEn = write;
    assign rst = ~nrst;

    wire [17:0] romAddr;
    wire romClkEn;
    wire [31:0] romQ;
    systemROM rom(
        .Address(romAddr[9:0]),
        .OutClock(clk),
        .OutClockEn(romClkEn),
        .Reset(rst),
        .Q(romQ)
    );

    wire [17:0] ramAddr;
    wire ramClkEn;
    wire ramWriteEn;
    wire [31:0] ramData;
    wire [31:0] ramQ;
    systemRAM ram(
        .Clock(clk),
        .ClockEn(ramClkEn),
        .Reset(rst),
        .WE(ramWriteEn),
        .Address(ramAddr[9:0]),
        .Data(ramData),
        .Q(ramQ)
    );

    DEMUX4 #(.BITS(1)) clkEnDemux(
        .addr(addr[19:18]),
        .in(clkEn),
        .out0(romClkEn),
        .out1(ramClkEn),
        .out2(devClkEn),
        .out3()
    );

    DEMUX4 #(.BITS(18)) addrDemux(
        .addr(addr[19:18]),
        .in(addr[17:0]),
        .out0(romAddr),
        .out1(ramAddr),
        .out2(devAddr),
        .out3()
    );

    DEMUX4 #(.BITS(1)) writeEnDemux(
        .addr(addr[19:18]),
        .in(writeEn),
        .out0(),
        .out1(ramWriteEn),
        .out2(devWriteEn),
        .out3()
    );

    DEMUX4 #(.BITS(32)) dataDemux(
        .addr(addr[19:18]),
        .in(data),
        .out0(),
        .out1(ramData),
        .out2(devData),
        .out3()
    );

    MUX4 #(.BITS(32)) Qmux(
        .addr(addr[19:18]),
        .in0(romQ),
        .in1(ramQ),
        .in2(devQ),
        .in3(32'b0),
        .out(Q)
    );

    assign devNrst = nrst;
    assign devClk = clk;

    reg [1:0] steps;
    reg pushMusk;
    assign pushOut = steps[1] & pushMusk;
    initial begin
        steps = 2'b0;
        pushMusk = 1'b0;
    end
    // steps
    always @(posedge clk or negedge nrst) begin
        if(~nrst) begin
            steps = 2'b0;
        end
        else if(clkEn) begin
            steps = 2'b01;
        end
        else begin
            steps = steps << 1;
        end
    end
    // pushMusk
    always @(negedge clk or negedge nrst) begin
        if(~nrst) begin
            pushMusk = 1'b0;
        end
        else if(steps[0]) begin
            pushMusk = 1'b1;
        end
        else begin
            pushMusk = 1'b0;
        end
    end
    // next
    always @(negedge clk or negedge nrst) begin
        if(~nrst) begin
            next = 1'b0;
        end
        else if(pushOut) begin
            next = 1'b1;
        end
        else begin
            next = 1'b0;
        end
    end


endmodule