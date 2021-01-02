module text_font (
    input clk,
    input [9:0] addr_r,
    output reg [7:0] data_r,
    );

`include "font/text_font.data.v"

always @(posedge clk) begin
    data_r <= text_font[addr_r];
end

endmodule

