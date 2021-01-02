module main (
    input CLK, 
    output PIN_14,
    output PIN_15,
    output PIN_16,
    output PIN_17,
    output PIN_18);

ridley _ridley (
    .clk (CLK),
    .vga_h_sync (PIN_14),
    .vga_v_sync (PIN_15),
    .vga_r (PIN_16),
    .vga_g (PIN_17),
    .vga_b (PIN_18));

endmodule

