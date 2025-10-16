# List of source files
SRC += $(SRC_DIR)/calc_prob.vhd
SRC += $(SRC_DIR)/lfsr.vhd
SRC += $(SRC_DIR)/core.vhd
SRC += $(SRC_DIR)/random.vhd
SRC += $(SRC_DIR)/pow2_rom.vhd
SRC += $(SRC_DIR)/pow2.vhd

# List of test specific simulation files
SRC += $(SIM_SRC_DIR)/tb_core.vhd
SRC += $(PLATFORM_SRC_DIR)/tdp_ram.vhd

# Top level entity
DUT = core

# Test duration
STOP_TIME = 1us

# Test specific generics
GENERIC += -gG_GRID_SIZE=8
GENERIC += -gG_ADDR_BITS=8
GENERIC += -gG_ACCURACY=12

include ../Makefile.inc

