`default_nettype none

module sine_table(
    input wire [4:0] in,
    output reg [10:0] out
);

always @(*) begin
    case(in)
        5'b00000: out = 11'b00000000001;
        5'b00001: out = 11'b00000000110;
        5'b00010: out = 11'b00000001111;
        5'b00011: out = 11'b00000011110;
        5'b00100: out = 11'b00000110010;
        5'b00101: out = 11'b00001001010;
        5'b00110: out = 11'b00001100111;
        5'b00111: out = 11'b00010001001;
        5'b01000: out = 11'b00010110000;
        5'b01001: out = 11'b00011011011;
        5'b01010: out = 11'b00100001010;
        5'b01011: out = 11'b00100111110;
        5'b01100: out = 11'b00101110110;
        5'b01101: out = 11'b00110110001;
        5'b01110: out = 11'b00111110001;
        5'b01111: out = 11'b01000110101;
        5'b10000: out = 11'b01001111100;
        5'b10001: out = 11'b01011000110;
        5'b10010: out = 11'b01100010100;
        5'b10011: out = 11'b01101100101;
        5'b10100: out = 11'b01110111000;
        5'b10101: out = 11'b10000001111;
        5'b10110: out = 11'b10001100111;
        5'b10111: out = 11'b10011000010;
        5'b11000: out = 11'b10100011111;
        5'b11001: out = 11'b10101111110;
        5'b11010: out = 11'b10111011110;
        5'b11011: out = 11'b11000111111;
        5'b11100: out = 11'b11010100010;
        5'b11101: out = 11'b11100000101;
        5'b11110: out = 11'b11101101001;
        5'b11111: out = 11'b11111001110;
    endcase
end

endmodule
