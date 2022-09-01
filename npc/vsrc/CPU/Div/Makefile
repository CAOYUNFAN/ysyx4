VSRC = $(shell find . -name "*.v")
CSRC = $(shell find ./test/ -name "*.cpp")
TOP_MODULE = ysyx_220066_Div
TARGET = ./emu_div/emu_div

$(TARGET): $(VSRC) $(CSRC)
	@echo "building"
	@verilator --cc -CFLAGS -g\
		--Mdir $(@D) --top-module $(TOP_MODULE) --prefix $(@F)\
		--exe $(CSRC) $(VSRC)\
		--report-unoptflat
	@make -C $(@D) -f $(@F).mk

sim: $(TARGET)
	$< 

.phony: sim,clear