
all: text_font.data.v

font.data: font_raw
	./font_raw > font.data

text_font.data.v: font.data
	../util/bin2verilog $< text_font > $@

clean:
	rm -f font.data font_raw text_font.data.v
