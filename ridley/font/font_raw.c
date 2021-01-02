#include <unistd.h>
#include <stdint.h>

#include "img.xbm"

#define FONT_HEIGHT 8
#define FONT_WIDTH 8

uint8_t BITS[8] = {1, 2, 4, 8, 16, 32, 64, 128};

int main () {
    // 96
    int fonts_nx = img_width / FONT_WIDTH;
    // 1
    int fonts_ny = img_height / FONT_HEIGHT;
    // 96
    int fonts_n = fonts_nx * fonts_ny;

    for (int c = 0; c < fonts_n; c ++) {
        uint8_t *_p = img_bits +
                ((c / fonts_nx) * fonts_nx * FONT_HEIGHT) +
                ((c % fonts_nx));

        for (int v = 0; v < FONT_HEIGHT; v ++) {
            // *_p is inverted and mirrored l/r
            uint8_t row = 0;
            for (int p = 0; p < 8; p ++)
                if (! (*_p & BITS[p]))
                   row |= BITS[7 - p];

            write(1, &row, FONT_WIDTH / 8);
            _p += fonts_nx;
        }
    }

    return 0;
}

