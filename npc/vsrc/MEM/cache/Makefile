VSRC = $(shell find . -name "*.v")
CSRC = $(shell find ./test/ -name "*.cpp")
TARGET = emu_cache/emu_cache
TOP_MODULE = ysyx_040066_cache_top
CFLAGS = -O2 -g #-DDEBUG
VFLAGS = -DTEST_CACHE #-DR_W -Dfully_info

$(TARGET):$(CSRC) $(VSRC)
	@echo "building"
	@verilator --cc --exe -Mdir $(@D) \
	$(addprefix -CFLAGS ,$(CFLAGS)) $(VFLAGS) \
	--top-module $(TOP_MODULE) --prefix $(@F) $(CSRC) $(VSRC)
	@make -C $(@F) -f $(@F).mk

sim: $(TARGET)
	$<

clear:
	rm -rf $(dir $(TARGET))

.PHONY: sim clear