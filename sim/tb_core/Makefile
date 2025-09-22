# List of source files
SRC += $(SRC_DIR)/calc_prob.vhd
SRC += $(SRC_DIR)/lfsr.vhd
SRC += $(SRC_DIR)/core.vhd
SRC += $(SRC_DIR)/random.vhd
SRC += $(SRC_DIR)/exp_rom.vhd
SRC += $(SRC_DIR)/exp.vhd

# List of test specific simulation files
SRC += $(SIM_SRC_DIR)/tb_core.vhd
SRC += $(PLATFORM_SRC_DIR)/tdp_ram.vhd

# Top level entity
DUT = core

# Test duration
STOP_TIME = 2000ns

# Test specific generics
GENERIC += -gG_GRID_SIZE=8
GENERIC += -gG_ADDR_BITS=4
GENERIC += -gG_ACCURACY=4

include ../Makefile.inc

