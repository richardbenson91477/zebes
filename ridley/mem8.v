module mem8 #(
      parameter D_LEN = 1024,
      parameter A_WID = 10) (
    input clk,
    input [A_WID - 1:0] addr_r,
    output reg [7:0] data_r,
    input [A_WID - 1:0] addr_w,
    input [7:0] data_w,
    input w_);

reg [7:0] mem [0:D_LEN - 1];

always @(posedge clk) begin
    data_r <= mem[addr_r];
    if (w_) 
        mem[addr_w] <= data_w;
end

endmodule

