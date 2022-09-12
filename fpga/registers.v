// module test (
//     input wire rawclk,
//     input wire [3:0] button,
//     input wire [3:0] switch,
//     output wire [7:0] nled,
//     output wire [8:0] digit0data,
//     output wire [8:0] digit1data
// );  
//     reg clk;
//     reg [31:0] counter;
//     initial counter = 32'b0;
//     initial clk = 1'b0;
//     always @(posedge rawclk ) begin
//         if(counter == 24_000_000) begin
//             counter <= 32'b0;
//             clk = 1'b0;
//         end
//         else begin
//             counter <= counter + 32'b1;
//         end
//         if(counter == 12_000_000) begin
//             clk = 1'b1;
//         end
//     end

//     wire [7:0] digits;
//     DigitDecoder digit0(
//         .in(digits[7:4]),
//         .out(digit0data)
//     );
//     DigitDecoder digit1(
//         .in(digits[3:0]),
//         .out(digit1data)
//     );
    
//     wire [7:0] led;
//     assign nled = ~led;

//     wire nrst;
//     assign nrst = button[0];
//     wire interrupt;
//     assign interrupt = button[1];

//     // cpu internal structure

//     // fist enable signal to start the cpu
//     // reg [31:0] initEnableCounter;
//     // reg initEnable;
//     // initial begin
//     //     initEnableCounter = 32'b0;
//     //     initEnable = 1'b0;
//     // end
//     // always @(negedge clk or negedge nrst) begin
//     //     if(~nrst) begin
//     //         initEnableCounter = 32'b0;
//     //         initEnable = 1'b0;
//     //     end
//     //     else begin
//     //         if(initEnable) begin
//     //             initEnable = 1'b0;
//     //         end
//     //         if(initEnableCounter < 32'd4) begin
//     //             initEnableCounter = initEnableCounter + 1;
//     //         end
//     //         if(initEnableCounter == 32'd3) begin
//     //             initEnable = 1'b1;
//     //         end
//     //     end
//     // end

//     reg regPush;
//     reg pcpp;

//     initial begin
//         regPush = 1'b0;
//         pcpp = 1'b0;
//     end

//     always @(posedge clk or negedge nrst) begin
//         if(~nrst) begin
//             regPush = 1'b0;
//             pcpp = 1'b0;
//         end
//         else begin
//             if(~button[2]) begin
//                 regPush = 1'b1;
//             end
//             else if(regPush) begin
//                 regPush = 1'b0;
//             end
//             if(~button[3]) begin
//                 pcpp = 1'b1;
//             end
//             else if(pcpp) begin
//                 pcpp = 1'b0;
//             end
//         end
//     end

//     wire [31:0] pcOut;
//     Registers registers(
//         .in1(32'd4),
//         .in2(32'd0),
//         .out1(),
//         .out2(),
//         .pc(pcOut),
//         .in1Addr(4'd14),
//         .in2Addr(4'd0),
//         .out1Addr(4'd0),
//         .out2Addr(4'd0),
//         .nrst(nrst),
//         .push(regPush),
//         .pcpp(pcpp)
//     );

//     // debug outputs
//     assign digits = {pcOut[7:0]};
//     assign led[0] = clk;
//     assign led[1] = pcpp;
//     assign led[2] = regPush;
//     assign led[7:3] = 5'b0;

// endmodule


module Registers (
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out1,
    output wire [31:0] out2,
    output wire [31:0] pc,
    input wire [3:0] in1Addr,
    input wire [3:0] in2Addr,
    input wire [3:0] out1Addr,
    input wire [3:0] out2Addr,
    input wire nrst,
    input wire push,
    input wire pcpp
);
    reg [31:0] r0;
    reg [31:0] r1;
    reg [31:0] r2;
    reg [31:0] r3;
    reg [31:0] r4;
    reg [31:0] r5;
    reg [31:0] r6;
    reg [31:0] r7;
    reg [31:0] r8;
    reg [31:0] r9;
    reg [31:0] r10;
    reg [31:0] r11;
    reg [31:0] r12;
    reg [31:0] r13; // SP
    reg [31:0] r14; // PC
    reg [31:0] r15; // JF

    MUX16 #(.BITS(32)) out1Mux(
        .addr(out1Addr),
        .in0(r0),
        .in1(r1),
        .in2(r2),
        .in3(r3),
        .in4(r4),
        .in5(r5),
        .in6(r6),
        .in7(r7),
        .in8(r8),
        .in9(r9),
        .in10(r10),
        .in11(r11),
        .in12(r12),
        .in13(r13),
        .in14(r14),
        .in15(r15),
        .out(out1)
    );
    MUX16 #(.BITS(32)) out2Mux(
        .addr(out2Addr),
        .in0(r0),
        .in1(r1),
        .in2(r2),
        .in3(r3),
        .in4(r4),
        .in5(r5),
        .in6(r6),
        .in7(r7),
        .in8(r8),
        .in9(r9),
        .in10(r10),
        .in11(r11),
        .in12(r12),
        .in13(r13),
        .in14(r14),
        .in15(r15),
        .out(out2)
    );
    assign pc = r14;

    initial begin
        r0 = 32'b0;
        r1 = 32'b0;
        r2 = 32'b0;
        r3 = 32'b0;
        r4 = 32'b0;
        r5 = 32'b0;
        r6 = 32'b0;
        r7 = 32'b0;
        r8 = 32'b0;
        r9 = 32'b0;
        r10 = 32'b0;
        r11 = 32'b0;
        r12 = 32'b0;
        r13 = 32'b0;
        r14 = 32'b0;
        r15 = 32'b0;
    end

    // r1 - r13
    always @(posedge push or negedge nrst) begin
        if(~nrst) begin
            r1 <= 32'b0;
            r2 <= 32'b0;
            r3 <= 32'b0;
            r4 <= 32'b0;
            r5 <= 32'b0;
            r6 <= 32'b0;
            r7 <= 32'b0;
            r8 <= 32'b0;
            r9 <= 32'b0;
            r10 <= 32'b0;
            r11 <= 32'b0;
            r12 <= 32'b0;
            r13 <= 32'b0;
        end
        else begin
            case (in1Addr)
                4'd1:r1 <= in1;
                4'd2:r2 <= in1;
                4'd3:r3 <= in1;
                4'd4:r4 <= in1;
                4'd5:r5 <= in1;
                4'd6:r6 <= in1;
                4'd7:r7 <= in1;
                4'd8:r8 <= in1;
                4'd9:r9 <= in1;
                4'd10:r10 <= in1;
                4'd11:r11 <= in1;
                4'd12:r12 <= in1;
                4'd13:r13 <= in1;
                default:;
            endcase
            case (in2Addr)
                4'd1:r1 <= in2;
                4'd2:r2 <= in2;
                4'd3:r3 <= in2;
                4'd4:r4 <= in2;
                4'd5:r5 <= in2;
                4'd6:r6 <= in2;
                4'd7:r7 <= in2;
                4'd8:r8 <= in2;
                4'd9:r9 <= in2;
                4'd10:r10 <= in2;
                4'd11:r11 <= in2;
                4'd12:r12 <= in2;
                4'd13:r13 <= in2;
                default:;
            endcase
        end
    end
    // pc & jf
    always @(posedge push or posedge pcpp or negedge nrst ) begin
        if(~nrst) begin
            r14 <= 32'b0;
            r15 <= 32'b0;
        end
        else if(push) begin
            case (in1Addr)
                4'd14:begin
                    r15 <= r14;
                    r14 <= in1;
                end 
                4'd15:r15 <= in1;
                default:;
            endcase
            case (in2Addr)
                4'd14:begin
                    r15 <= r14;
                    r14 <= in2;
                end 
                4'd15:r15 <= in2;
                default:;
            endcase
        end
        else begin
            r14 <= r14 + 1'b1;
        end
    end

endmodule