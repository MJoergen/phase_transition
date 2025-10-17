library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_top is
  generic (
    G_ACCURACY     : natural;
    G_ADDR_BITS    : natural;
    G_SCALING_BITS : natural;
    G_GRID_SIZE    : natural
  );
end entity tb_top;

architecture simulation of tb_top is

  constant C_TIMESTAMP : std_logic_vector(31 downto 0) := X"12345678";
  constant C_COMMIT_ID : std_logic_vector(31 downto 0) := X"87654321";

  signal   running      : std_logic                    := '1';
  signal   sys_clk      : std_logic                    := '1';
  signal   sys_rst      : std_logic                    := '1';
  signal   kb_io0       : std_logic;
  signal   kb_io1       : std_logic;
  signal   kb_io2       : std_logic                    := '1';
  signal   vdac_blank_n : std_logic;
  signal   vdac_clk     : std_logic;
  signal   vdac_psave_n : std_logic;
  signal   vdac_sync_n  : std_logic;
  signal   vga_blue     : std_logic_vector(7 downto 0);
  signal   vga_green    : std_logic_vector(7 downto 0);
  signal   vga_hs       : std_logic;
  signal   vga_red      : std_logic_vector(7 downto 0);
  signal   vga_vs       : std_logic;

begin

  sys_clk <= running and not sys_clk after 5 ns;
  sys_rst <= '1', '0' after 100 ns;

  top_inst : entity work.top
    generic map (
      G_TIMESTAMP    => C_TIMESTAMP,
      G_COMMIT_ID    => C_COMMIT_ID,
      G_GRID_SIZE    => G_GRID_SIZE,
      G_ADDR_BITS    => G_ADDR_BITS,
      G_SCALING_BITS => G_SCALING_BITS,
      G_ACCURACY     => G_ACCURACY
    )
    port map (
      sys_clk_i      => sys_clk,
      sys_rst_i      => sys_rst,
      kb_io0_o       => kb_io0,
      kb_io1_o       => kb_io1,
      kb_io2_i       => kb_io2,
      vdac_blank_n_o => vdac_blank_n,
      vdac_clk_o     => vdac_clk,
      vdac_psave_n_o => vdac_psave_n,
      vdac_sync_n_o  => vdac_sync_n,
      vga_blue_o     => vga_blue,
      vga_green_o    => vga_green,
      vga_hs_o       => vga_hs,
      vga_red_o      => vga_red,
      vga_vs_o       => vga_vs
    ); -- top_inst : entity work.top

end architecture simulation;

