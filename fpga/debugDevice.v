module DebugDevice (
    // memory interface
    input wire memNrst,
    input wire memClk,
    input wire memClkEn,
    input wire memWE,
    input wire [31:0] memData,
    input wire [17:0] memAddr,
    output wire [31:0] memQ,
    // device output
    output reg [31:0] data
);
    initial begin
        data = 32'b0;
    end
    always @(posedge memClk or negedge memNrst) begin
        if(~memNrst) begin
            data = 32'b0;
        end
        else if(memClkEn & memWE) begin
            data = memData;
        end
    end
endmodule