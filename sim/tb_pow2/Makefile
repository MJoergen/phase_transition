# List of source files
SRC += $(SRC_DIR)/pow2_rom.vhd
SRC += $(SRC_DIR)/pow2.vhd

# List of test specific simulation files
SRC += $(SIM_SRC_DIR)/tb_pow2.vhd

# Top level entity
DUT = pow2

# Test duration
STOP_TIME = 6us

# Test specific generics
GENERIC += -gG_ACCURACY=4

include ../Makefile.inc

