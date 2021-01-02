ifndef PCF
  PCF="TinyFPGA-BX-pins.pcf"
endif

all: main.bin

main.json: main.v ridley.v vga_gen.v mem8.v text_font.v
	yosys -q -p "synth_ice40 -json $@" $^

main.asc: main.json
	nextpnr-ice40 --lp8k --freq 16 --package cm81 --json $< --asc $@ --pcf $(PCF) -q 

main.bin: main.asc
	icepack $< $@

upload: main.bin
	tinyprog --pyserial --program $<

%.verilog: %.v
	yosys -q -p "synth_ice40; write_verilog" $<

clean:
	rm -f main.bin main.asc main.json

