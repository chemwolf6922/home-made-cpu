module DigitDecoder (
    input wire [3:0] in,
    output wire [8:0] out
);
    assign out = (in==4'h0)?9'b0_0011_1111:
                (in==4'h1)?9'b0_0000_0110:
                (in==4'h2)?9'b0_0101_1011:
                (in==4'h3)?9'b0_0100_1111:
                (in==4'h4)?9'b0_0110_0110:
                (in==4'h5)?9'b0_0110_1101:
                (in==4'h6)?9'b0_0111_1101:
                (in==4'h7)?9'b0_0000_0111:
                (in==4'h8)?9'b0_0111_1111:
                (in==4'h9)?9'b0_0110_1111:
                (in==4'ha)?9'b0_0111_0111:
                (in==4'hb)?9'b0_0111_1100:
                (in==4'hc)?9'b0_0011_1001:
                (in==4'hd)?9'b0_0101_1110:
                (in==4'he)?9'b0_0111_1001:
                9'b0_0111_0001;
endmodule