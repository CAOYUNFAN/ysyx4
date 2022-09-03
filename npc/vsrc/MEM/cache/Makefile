VSRC = $(shell find . -name "*.v")
CSRC = $(shell find ./test/ -name "*.cpp")
TARGET = emu_cache/emu_cache
TOP_MODULE = ysyx_220066_cache

$(TARGET):$(CSRC) $(VSRC)
	@echo "building"
	@verilator --cc --exe -Mdir $(@D) --top-module 