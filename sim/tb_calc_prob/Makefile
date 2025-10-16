# List of source files
SRC += $(SRC_DIR)/pow2_rom.vhd
SRC += $(SRC_DIR)/pow2.vhd
SRC += $(SRC_DIR)/calc_prob.vhd

# List of test specific simulation files
SRC += $(SIM_SRC_DIR)/tb_calc_prob.vhd

# Top level entity
DUT = calc_prob

# Test duration
STOP_TIME = 1us

# Test specific generics
GENERIC += -gG_ACCURACY=10

include ../Makefile.inc

