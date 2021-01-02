// based on https://www.fpga4fun.com/PongGame.html
// modified for alternate clk freq
//
module vga_gen (
    input clk,
    output reg h_sync,
    output reg v_sync,
    output reg [9:0] x,
    output reg [9:0] y);

// 16MHz
parameter clk_freq = 16000000;
// clk_freq / x_max = 31.46875 KHz = x_max = clk_freq / 31469
parameter x_max = 508;
// 31468 / y_max = 60 Hz = y_max = 31469 / 60
parameter y_max = 524;

always @(posedge clk) begin
    if (x == x_max) begin
        x <= 0;
        y <= y + 1;
        if (y == y_max)
            y <= 0;
    end
    else
        x <= x + 1;

	h_sync <= x < (x_max - 8);
	v_sync <= y < y_max;
end

endmodule

