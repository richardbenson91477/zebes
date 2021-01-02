module ridley (
    input clk, 
    output vga_h_sync,
    output vga_v_sync,
    output reg vga_r,
    output reg vga_g,
    output reg vga_b);

wire [9:0] vga_x;
wire [9:0] vga_y;

vga_gen _vga (
    .clk (clk),
    .h_sync (vga_h_sync),
    .v_sync (vga_v_sync),
    .x (vga_x),
    .y (vga_y));

// screen
parameter screen_l = 81;
parameter screen_r = 489;
parameter screen_t = 35;
parameter screen_b = 515;
parameter screen_xs = screen_r - screen_l; // 408
parameter screen_ys = screen_b - screen_t; // 480

wire screen_ = 
    (vga_x >= screen_l) && (vga_x < screen_r) && 
    (vga_y >= screen_t) && (vga_y < screen_b);

// view (inside border)
parameter view_xs = text_fb_xs * text_xs; // 400
parameter view_ys = text_fb_ys * (text_ys * 2); // 464
parameter view_l = screen_l + ((screen_xs - view_xs) / 2);
parameter view_r = view_l + view_xs;
parameter view_t = screen_t + ((screen_ys - view_ys) / 2);
parameter view_b = view_t + view_ys;

wire view_ = 
    (vga_x >= view_l) && (vga_x < view_r) &&
    (vga_y >= view_t) && (vga_y < view_b);

wire view_ahead_1_ = 
    (vga_x + 1 >= view_l) && (vga_x + 1 < view_r) &&
    (vga_y >= view_t) && (vga_y < view_b);

wire view_ahead_2_ = 
    (vga_x + 2 >= view_l) && (vga_x + 2 < view_r) &&
    (vga_y >= view_t) && (vga_y < view_b);

// text (in view)
parameter text_xs = 8;
parameter text_ys = 8;

wire [5:0] text_x = (vga_x - view_l) / text_xs;
wire [5:0] text_y = (vga_y - view_t) / (text_ys * 2);
wire [2:0] text_x_sub = (vga_x - view_l) % text_xs;
wire [2:0] text_y_sub = ((vga_y - view_t) % (text_ys * 2)) / 2;
wire [5:0] text_x_ahead_2 = (vga_x + 2 - view_l) / text_xs;

parameter text_fb_xs = 50;
parameter text_fb_ys = 29;

reg [10:0] text_fb_addr_r;
wire [7:0] text_fb_data_r;
reg [10:0] text_fb_addr_w;
reg [7:0] text_fb_data_w;
reg text_fb_w_;
mem8 #(
      .D_LEN (text_fb_xs * text_fb_ys),
      .A_WID (11))
    text_fb (
        .clk (clk),
        .addr_r (text_fb_addr_r),
        .data_r (text_fb_data_r),
        .addr_w (text_fb_addr_w),
        .data_w (text_fb_data_w),
        .w_ (text_fb_w_));

reg text_fb_vis_;

initial begin
    text_fb_w_ = 0;
    text_fb_vis_ = 1;
end

reg [9:0] text_font_addr_r;
wire [7:0] text_font_data_r;
text_font _text_font (
    .clk (clk),
    .addr_r (text_font_addr_r),
    .data_r (text_font_data_r),
    );

wire text_ = view_ && text_fb_vis_ &&
    text_font_data_r[7 - text_x_sub];

always @(posedge clk) begin
//    if (state == STATE_SCRDOWN) begin
//        text_fb_addr_r <= state_scrdown_addr_r;
//    end
//    else begin
    if (view_ahead_2_)
        text_fb_addr_r = text_y * text_fb_xs + text_x_ahead_2;
    if (view_ahead_1_)
        text_font_addr_r = text_fb_data_r * text_ys + text_y_sub;
end

// cursor
reg [5:0] cursor_x;
reg [5:0] cursor_y;
reg cursor_en_;
reg cursor_vis_;
reg [24:0] cursor_delay_n; // < 33,554,432
reg [24:0] cursor_delay_c;

initial begin
    cursor_delay_c = 0;
end

task cursor_tick; begin
    if (cursor_en_) begin
        cursor_delay_c = cursor_delay_c + 1;
        if (cursor_delay_c == cursor_delay_n) begin
            cursor_delay_c <= 0;
            cursor_vis_ <= ~cursor_vis_;
        end
    end
end
endtask

wire cursor_ = cursor_en_ && cursor_vis_ &&
    (cursor_x == text_x) && 
    (cursor_y == text_y);

// colors
wire border_ = screen_ && !view_;
wire bg_ = view_ && !text_ && !cursor_;

reg [2:0] color_border;
reg [2:0] color_bg;
reg [2:0] color_text;
reg [2:0] color_cursor;

always @(posedge clk) begin
    vga_r <=
        (border_ & color_border[0]) ||
        (bg_ & color_bg[0]) ||
        (text_ & !cursor_ & color_text[0]) ||
        (cursor_ & !text_ & color_cursor[0]);
    vga_g <=
        (border_ & color_border[1]) ||
        (bg_ & color_bg[1]) ||
        (text_ & !cursor_ & color_text[1]) ||
        (cursor_ & !text_ & color_cursor[1]);
    vga_b <=
        (border_ & color_border[2]) ||
        (bg_ & color_bg[2]) ||
        (text_ & !cursor_ & color_text[2]) ||
        (cursor_ & !text_ & color_cursor[2]);
end

// setting defaults
parameter def_cursor_x = 0;
parameter def_cursor_y = 0;
parameter def_cursor_en = 1;
parameter def_cursor_vis = 1;
parameter def_cursor_delay_n = 8_000_000;

parameter def_color_border = 3'b101;
parameter def_color_bg = 3'b000;
parameter def_color_text = 3'b101;
parameter def_color_cursor = 3'b010;

task reg_defaults; begin
    cursor_x <= def_cursor_x;
    cursor_y <= def_cursor_y;
    cursor_en_ <= def_cursor_en;;
    cursor_vis_ <= def_cursor_vis;
    cursor_delay_n <= def_cursor_delay_n;

    color_border <= def_color_border;
    color_bg <= def_color_bg;
    color_text <= def_color_text;
    color_cursor <= def_color_cursor;
end
endtask

// state machine
parameter STATE_INIT = 0;
parameter STATE_IDLE = 1;
parameter STATE_DELAY = 2;
parameter STATE_TEST = 3;
parameter STATE_CLS = 4;
parameter STATE_CURSORPOS = 5;
parameter STATE_PUTCHAR = 6;
parameter STATE_SCRDOWN = 7;

reg [3:0] state;
reg [31:0] state_c;
reg [31:0] state_delay_c;
reg [31:0] state_delay_n;
reg [3:0] state_next;
reg [3:0] state_test_c;
reg [10:0] state_cursorpos_pos;
reg [7:0] state_putchar_ch;
reg state_scrdown_w_;
reg [5:0] state_scrdown_x;
reg [5:0] state_scrdown_y;
reg [10:0] state_scrdown_addr_r;

initial begin
    state = STATE_INIT;
    state_c = 0;
    state_delay_c = 0;
//    state_test_c = 0;
state_test_c = 10;
    state_cursorpos_pos = 0;
    state_putchar_ch = 0;
    state_scrdown_w_ = 0;
    state_scrdown_x = 0;
    state_scrdown_y = 0;
end

always @(posedge clk) begin
    case (state)
        STATE_INIT: begin
            reg_defaults ();

            state_next <= STATE_TEST;
            state_delay_n <= 32_000_000; // monitor + memory warm up 
            state <= STATE_DELAY;
        end
        STATE_IDLE: begin 
            cursor_tick ();
        end
        STATE_DELAY: begin
            cursor_tick ();

            state_delay_c = state_delay_c + 1;
            if (state_delay_c == state_delay_n) begin
                state_delay_c <= 0;

                cursor_vis_ <= def_cursor_vis;

                state <= state_next;
            end
        end
        STATE_TEST: begin
            if (state_test_c == 0) begin // test font
                text_fb_addr_w = state_c[10:0];
                text_fb_data_w = text_fb_data_w + 1;
                if (text_fb_data_w == 96)
                    text_fb_data_w = 1;
                text_fb_w_ <= 1;

                state_c = state_c + 1;
                if (state_c == text_fb_xs * text_fb_ys) begin
                    state_c <= 0;

                    text_fb_w_ <= 0;

                    state_test_c = state_test_c + 1;
                end
            end
            else if (state_test_c < 8) begin // test colors
                color_border = state_test_c;
                color_bg = state_test_c;
                color_text <= 0;

                state_test_c <= state_test_c + 1;

                state_next <= STATE_TEST;
                state_delay_n <= 16_000_000;
                state <= STATE_DELAY;
            end
            else if (state_test_c == 8) begin // test CLS
                color_border <= def_color_border;
                color_bg <= def_color_bg;
                color_text <= def_color_text;

                state_test_c <= state_test_c + 1;

                state_next = STATE_TEST;
                state <= STATE_CLS;
            end
            else if (state_test_c == 9) begin // test CURSORPOS
                state_delay_c = state_delay_c + 1;
                if (state_delay_c == 1_000_000) begin
                    state_delay_c <= 0;

                    state_cursorpos_pos[10:6] = state_cursorpos_pos[10:6] + 1;
                    if (state_cursorpos_pos[10:6] == text_fb_ys)
                        state_cursorpos_pos[10:6] <= 0;

                    state_cursorpos_pos[5:0] = state_cursorpos_pos[5:0] + 1;
                    if (state_cursorpos_pos[5:0] == text_fb_xs) begin
                        state_cursorpos_pos[5:0] <= 0;

                        state_cursorpos_pos[10:6] <= 0;
                        cursor_x <= 0;
                        cursor_y <= 0;
                        state_test_c = state_test_c + 1;
                    end
                    else begin
                        state_next <= STATE_TEST;
                        state <= STATE_CURSORPOS;
                    end
                end
            end
            else if (state_test_c == 10) begin // test PUTCHAR
                if (  (cursor_x == text_fb_xs - 1) &&
                      (cursor_y == text_fb_ys - 1)) begin
                    state_test_c = state_test_c + 1;

                    state_next <= STATE_TEST;
                    state_delay_n <= 8_000_000;
                    state <= STATE_DELAY;
                end
                else begin
                    state_putchar_ch = 1 +
                        ((cursor_x + 1) * (cursor_y + 1) >> 4);

                    state_next <= STATE_TEST;
                    state <= STATE_PUTCHAR;
                end
            end
            else if (state_test_c == 11) begin // test SCRDOWN
                state_delay_c = state_delay_c + 1;
                if (state_delay_c == 16_000_000) begin
                    state_delay_c <= 0;

                    state_c = state_c + 1;
                    if (state_c == text_ys * 2) begin // 2 phases per y
                        state_c <= 0;

                        state_test_c = state_test_c + 1;
                    end
                    else begin
                        state_next <= STATE_TEST;
                        state <= STATE_SCRDOWN;
                    end
                end
            end
            else begin
                state_test_c <= 0;

                cursor_x <= 0;
                cursor_y <= 0;

                state_next = STATE_IDLE;
                state <= STATE_CLS;
            end
        end
        STATE_CLS: begin
            text_fb_addr_w = state_c[10:0];
            text_fb_data_w <= 0;
            text_fb_w_ <= 1;

            state_c = state_c + 1;
            if (state_c == text_fb_xs * text_fb_ys) begin
                state_c <= 0;

                text_fb_w_ <= 0;

                state <= state_next;
            end
        end
        STATE_CURSORPOS: begin
            cursor_x <= state_cursorpos_pos[5:0];
            cursor_y <= state_cursorpos_pos[10:6];
            cursor_delay_c <= 0;

            state <= state_next;
        end
        STATE_PUTCHAR: begin
            text_fb_addr_w = cursor_y * text_fb_xs + cursor_x;
            text_fb_data_w <= state_putchar_ch;
            text_fb_w_ <= 1;

            cursor_delay_c <= 0;

            cursor_x = cursor_x + 1;
            if (cursor_x == text_fb_xs) begin
                if (cursor_y != text_fb_ys - 1) begin
                    cursor_x <= 0;
                    cursor_y <= cursor_y + 1;
                end
                else begin
                    cursor_x <= text_fb_xs - 1;

                    text_fb_w_ <= 0;
                end
            end

            state <= state_next;
        end
        STATE_SCRDOWN: begin
            /*
            if (state_scrdown_w_) begin
                text_fb_addr_w = state_scrdown_y * text_fb_xs + state_scrdown_x;
                text_fb_data_w = state_scrdown_y < text_fb_ys - 1 ?
                    text_fb_data_r : 0;
                text_fb_w_ <= 1;

                state_scrdown_x = state_scrdown_x + 1;
                if (state_scrdown_x == text_fb_xs) begin
                    state_scrdown_x <= 0;
                    state_scrdown_y = state_scrdown_y + 1;
                    if (state_scrdown_y == text_fb_ys) begin
                        state_scrdown_y <= 0;

                        state <= state_next;
                    end
                end
                else begin
                    state_scrdown_w_ <= 0;
                end
            end
            else begin
                state_scrdown_addr_r <=
                    state_scrdown_y * text_fb_xs + state_scrdown_x;

                state_scrdown_w_ <= 1;
            end
            */
            state <= state_next;
        end
        //default: begin
        //end
    endcase;
end

endmodule

// NOTES
//
// always delay on init at least 40 ticks due to an ice40 memory bug
//
// (c / 4) + (c / 16) + ... ) approximates c / 3
//
// if tinyfpga-bx metadata breaks and tinyprog won't run: change __main__.py to say
// 'if check_if_overwrite_bootloader(addr, len(bitstream), [0x28000, 0x50000]):'

