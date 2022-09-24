VSRC = $(shell find . -name "*.v")
CSRC = $(shell find ./test/ -name "*.cpp")
TOP_MODULE = ysyx_040066_booth_walloc
TARGET = ./emu_multi/emu_multi

$(TARGET): $(VSRC) $(CSRC)
	@echo "building"
	@verilator --cc\
		--Mdir $(@D) --top-module $(TOP_MODULE) --prefix $(@F)\
		--exe $(CSRC) $(VSRC)\
		--report-unoptflat
	@make -C $(@D) -f $(@F).mk

sim: $(TARGET)
	$< 

clear:
	rm -rf $(dir $(TARGET))

.PHONY:sim clear
