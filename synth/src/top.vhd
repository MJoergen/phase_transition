library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

library unisim;
  use unisim.vcomponents.all;

library xpm;
  use xpm.vcomponents.all;

entity top is
  generic (
    G_TIMESTAMP    : std_logic_vector(31 downto 0);
    G_COMMIT_ID    : std_logic_vector(31 downto 0);
    G_GRID_SIZE    : natural;
    G_ADDR_BITS    : natural;
    G_SCALING_BITS : natural;
    G_ACCURACY     : natural
  );
  port (
    sys_clk_i      : in    std_logic;
    sys_rst_i      : in    std_logic;

    -- Connect to MEGA65 I/Os
    kb_io0_o       : out   std_logic;
    kb_io1_o       : out   std_logic;
    kb_io2_i       : in    std_logic;
    vdac_blank_n_o : out   std_logic;
    vdac_clk_o     : out   std_logic;
    vdac_psave_n_o : out   std_logic;
    vdac_sync_n_o  : out   std_logic;
    vga_blue_o     : out   std_logic_vector(7 downto 0);
    vga_green_o    : out   std_logic_vector(7 downto 0);
    vga_hs_o       : out   std_logic;
    vga_red_o      : out   std_logic_vector(7 downto 0);
    vga_vs_o       : out   std_logic
  );
end entity top;

architecture synthesis of top is

  -- Temperature is limited to the range [0, 1[.
  -- Chemical Potential is in the range ]-4, 0].
  --   Note: Only the absolute value is stored, i.e. in the range [0, 4[
  constant C_INITIAL_TEMPERATURE : real                      := 0.3;
  constant C_INITIAL_CHEM_POT    : real                      := -2.5;

  signal   core_clk          : std_logic;
  signal   core_rst          : std_logic;
  signal   core_temperature  : ufixed(-1 downto -G_ACCURACY) := to_ufixed(C_INITIAL_TEMPERATURE, -1, -G_ACCURACY);
  signal   core_neg_chem_pot : ufixed(1 downto -G_ACCURACY)  := to_ufixed(-C_INITIAL_CHEM_POT, 1, -G_ACCURACY);
  signal   core_ram_addr     : std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
  signal   core_ram_wr_data  : std_logic;
  signal   core_ram_rd_data  : std_logic;
  signal   core_ram_wr_en    : std_logic;
  signal   core_step         : std_logic;

  signal   vga_clk         : std_logic;
  signal   vga_rst         : std_logic;
  signal   vga_ram_addr    : std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
  signal   vga_ram_rd_data : std_logic;
  signal   vga_step        : std_logic;


begin

  ----------------------------------
  -- Generate clock and reset
  ----------------------------------

  clk_rst_inst : entity work.clk_rst
    port map (
      sys_clk_i  => sys_clk_i,
      sys_rst_i  => sys_rst_i,
      core_clk_o => core_clk,
      core_rst_o => core_rst,
      vga_clk_o  => vga_clk,
      vga_rst_o  => vga_rst
    ); -- clk_rst_inst : entity work.clk_rst


  ----------------------------------
  -- Instantiate CORE
  ----------------------------------

  core_inst : entity work.core
    generic map (
      G_ACCURACY  => G_ACCURACY,
      G_ADDR_BITS => G_ADDR_BITS,
      G_GRID_SIZE => G_GRID_SIZE
    )
    port map (
      clk_i          => core_clk,
      rst_i          => core_rst,
      step_i         => core_step,
      temperature_i  => core_temperature,
      neg_chem_pot_i => core_neg_chem_pot,
      ram_addr_o     => core_ram_addr,
      ram_wr_data_o  => core_ram_wr_data,
      ram_rd_data_i  => core_ram_rd_data,
      ram_wr_en_o    => core_ram_wr_en
    ); -- core_inst : entity work.core


  ----------------------------------
  -- Instantiate MEGA65 Wrapper
  ----------------------------------

  mega65_wrapper_inst : entity work.mega65_wrapper
    generic map (
      G_ADDR_BITS    => G_ADDR_BITS,
      G_SCALING_BITS => G_SCALING_BITS,
      G_GRID_SIZE    => G_GRID_SIZE
    )
    port map (
      vga_clk_i         => vga_clk,
      vga_rst_i         => vga_rst,
      vga_ram_addr_o    => vga_ram_addr,
      vga_ram_rd_data_i => vga_ram_rd_data,
      vga_step_o        => vga_step,
      kb_io0_o          => kb_io0_o,
      kb_io1_o          => kb_io1_o,
      kb_io2_i          => kb_io2_i,
      vdac_blank_n_o    => vdac_blank_n_o,
      vdac_clk_o        => vdac_clk_o,
      vdac_psave_n_o    => vdac_psave_n_o,
      vdac_sync_n_o     => vdac_sync_n_o,
      vga_blue_o        => vga_blue_o,
      vga_green_o       => vga_green_o,
      vga_hs_o          => vga_hs_o,
      vga_red_o         => vga_red_o,
      vga_vs_o          => vga_vs_o
    ); -- mega65_wrapper_inst : entity work.mega65_wrapper


  ----------------------------------
  -- Clock Domain Crossings
  ----------------------------------

  tdp_ram_inst : entity work.tdp_ram
    generic map (
      G_ADDR_SIZE => 2 * G_ADDR_BITS,
      G_DATA_SIZE => 1
    )
    port map (
      a_clk_i        => core_clk,
      a_rst_i        => core_rst,
      a_addr_i       => core_ram_addr,
      a_wr_en_i      => core_ram_wr_en,
      a_wr_data_i(0) => core_ram_wr_data,
      a_rd_en_i      => '1',
      a_rd_data_o(0) => core_ram_rd_data,
      b_clk_i        => vga_clk,
      b_rst_i        => vga_rst,
      b_addr_i       => vga_ram_addr,
      b_wr_en_i      => '0',
      b_wr_data_i    => (others => '0'),
      b_rd_en_i      => '1',
      b_rd_data_o(0) => vga_ram_rd_data
    ); -- tdp_ram_inst : entity work.tdp_ram


  xpm_cdc_pulse_inst : component xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF   => 2,
      INIT_SYNC_FF   => 0,
      REG_OUTPUT     => 1,
      RST_USED       => 1,
      SIM_ASSERT_CHK => 0
    )
    port map (
      src_clk    => vga_clk,
      src_rst    => vga_rst,
      src_pulse  => vga_step,
      dest_clk   => core_clk,
      dest_rst   => core_rst,
      dest_pulse => core_step
    ); -- xpm_cdc_single_inst : component xpm_cdc_single

end architecture synthesis;

