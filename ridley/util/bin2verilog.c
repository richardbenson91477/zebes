#include <stdio.h>
#include <stdint.h>

int main (int argc, char *argv[]) {
    if (argc < 3) {
        fprintf (stderr, "Usage: %s filename data_name\n", argv[0]);
        return -1;
    }

    FILE *f_in = fopen (argv[1], "r");
    if (! f_in) {
        fprintf (stderr, "Error: can't open %s\n", argv[1]);
        return -2;
    }
    fseek (f_in, 0, SEEK_END);
    uint64_t n = ftell(f_in);
    fseek (f_in, 0, SEEK_SET);

    const char *name = argv[2];    

    printf ("reg [7:0] %s [0:%lu];\n", name, n - 1);
    printf ("initial begin\n");

    for (uint64_t c = 0; c < n; c++) {
        printf ("    %s[%d] = 8\'d%d;\n", name, c, fgetc(f_in));
    }
    fclose (f_in);
    
    printf ("end\n");
    return 0;
}

