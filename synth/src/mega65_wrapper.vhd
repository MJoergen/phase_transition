library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;

library xpm;
  use xpm.vcomponents.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.video_modes_pkg.all;

entity mega65_wrapper is
  generic (
    G_ADDR_BITS    : natural;
    G_SCALING_BITS : natural;
    G_GRID_SIZE    : natural
  );
  port (
    -- Connect to design
    vga_clk_i         : in    std_logic;
    vga_rst_i         : in    std_logic;
    vga_ram_addr_o    : out   std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
    vga_ram_rd_data_i : in    std_logic;
    vga_key_valid_o   : out   std_logic;
    vga_key_code_o    : out   integer range 0 to 79;

    -- Connect to MEGA65 I/Os
    kb_io0_o          : out   std_logic;
    kb_io1_o          : out   std_logic;
    kb_io2_i          : in    std_logic;
    vdac_blank_n_o    : out   std_logic;
    vdac_clk_o        : out   std_logic;
    vdac_psave_n_o    : out   std_logic;
    vdac_sync_n_o     : out   std_logic;
    vga_blue_o        : out   std_logic_vector(7 downto 0);
    vga_green_o       : out   std_logic_vector(7 downto 0);
    vga_hs_o          : out   std_logic;
    vga_red_o         : out   std_logic_vector(7 downto 0);
    vga_vs_o          : out   std_logic
  );
end entity mega65_wrapper;

architecture synthesis of mega65_wrapper is

  constant C_VIDEO_MODE : video_modes_type := C_VIDEO_MODE_1280_720_60;
  constant C_POS_X      : natural          := 0;
  constant C_POS_Y      : natural          := 0;

  signal   vga_key_num       : integer range 0 to 79;
  signal   vga_key_pressed_n : std_logic;

  signal   vga_hcount : std_logic_vector(C_VIDEO_MODE.PIX_SIZE - 1 downto 0);
  signal   vga_vcount : std_logic_vector(C_VIDEO_MODE.PIX_SIZE - 1 downto 0);
  signal   vga_de     : std_logic;
  signal   vga_hs     : std_logic;
  signal   vga_vs     : std_logic;
  --
  signal   vga_char   : std_logic_vector(7 downto 0);
  signal   vga_colors : std_logic_vector(15 downto 0);
  signal   vga_rgb    : std_logic_vector(7 downto 0);
  signal   vga_x      : std_logic_vector(7 downto 0);
  signal   vga_y      : std_logic_vector(7 downto 0);

begin

  -------------------------------------------
  -- Keyboard (in VGA clock domain)
  -------------------------------------------

  m2m_keyb_inst : entity work.m2m_keyb
    port map (
      clk_main_i       => vga_clk_i,
      clk_main_speed_i => C_VIDEO_MODE.CLK_KHZ * 1000,
      kio8_o           => kb_io0_o,
      kio9_o           => kb_io1_o,
      kio10_i          => kb_io2_i,
      enable_core_i    => '1',
      key_num_o        => vga_key_num,
      key_pressed_n_o  => vga_key_pressed_n,
      power_led_i      => '1',
      power_led_col_i  => X"CC4444",
      drive_led_i      => '1',
      drive_led_col_i  => X"44CC44",
      qnice_keys_n_o   => open
    ); -- m2m_keyb_inst : entity work.m2m_keyb

  vga_key_valid_o <= not vga_key_pressed_n;
  vga_key_code_o  <= vga_key_num;


  -------------------------------------------
  -- VGA
  -------------------------------------------

  video_sync_inst : entity work.video_sync
    generic map (
      G_VIDEO_MODE => C_VIDEO_MODE
    )
    port map (
      clk_i     => vga_clk_i,
      rst_i     => vga_rst_i,
      vs_o      => vga_vs,
      hs_o      => vga_hs,
      de_o      => vga_de,
      pixel_x_o => vga_hcount,
      pixel_y_o => vga_vcount
    ); -- video_sync_inst : entity work.video_sync


  vga_ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= vga_vcount(G_SCALING_BITS + G_ADDR_BITS - 1 downto G_SCALING_BITS);
  vga_ram_addr_o(G_ADDR_BITS - 1 downto 0)               <= vga_hcount(G_SCALING_BITS + G_ADDR_BITS - 1 downto G_SCALING_BITS);

  vga_char_proc : process (vga_clk_i)
    variable col_v : natural range 0 to 7;
    variable row_v : natural range 0 to G_GRID_SIZE - 1;
    variable idx_v : natural range 0 to G_GRID_SIZE * 8 - 1;

    pure function to_ascii (
      arg : std_logic_vector(3 downto 0)
    ) return std_logic_vector is
    begin
      if arg < 10 then
        return to_stdlogicvector(character'pos('0') + to_integer(arg), 8);
      else
        return to_stdlogicvector(character'pos('A') + to_integer(arg) - 10, 8);
      end if;
    end function to_ascii;

  --
  begin
    if rising_edge(vga_clk_i) then
      vga_char   <= x"20";
      vga_colors <= x"AA55";
      if vga_x >= C_POS_X and vga_x < C_POS_X + G_GRID_SIZE and
         vga_y >= C_POS_Y and vga_y < C_POS_Y + G_GRID_SIZE then
        col_v      := 7 - to_integer(vga_x - C_POS_X);
        row_v      := to_integer(vga_y - C_POS_Y);
        idx_v      := row_v * 8 + col_v;
        vga_colors <= x"44BB";
        vga_char   <= "0011000" & vga_ram_rd_data_i;
      end if;
      if vga_x >= C_POS_X and vga_x < C_POS_X + G_GRID_SIZE and
         vga_y = C_POS_Y + G_GRID_SIZE then
        vga_colors <= x"2DD2";
        vga_char   <= X"41" + vga_x - C_POS_X;
      end if;
    end if;
  end process vga_char_proc;

  video_chars_inst : entity work.video_chars
    generic map (
      G_SCALING    => G_SCALING_BITS,
      G_FONT_FILE  => "font8x8.txt",
      G_VIDEO_MODE => C_VIDEO_MODE
    )
    port map (
      video_clk_i    => vga_clk_i,
      video_hcount_i => vga_hcount,
      video_vcount_i => vga_vcount,
      video_blank_i  => not vga_de,
      video_rgb_o    => vga_rgb,
      video_x_o      => vga_x,
      video_y_o      => vga_y,
      video_char_i   => vga_char,
      video_colors_i => vga_colors
    ); -- video_chars_inst : entity work.video_chars

  vga_proc : process (vga_clk_i)
  begin
    if rising_edge(vga_clk_i) then
      vga_vs_o    <= vga_vs;
      vga_hs_o    <= vga_hs;
      vga_blue_o  <= (others => '0');
      vga_green_o <= (others => '0');
      vga_red_o   <= (others => '0');

      if vga_de = '1' then
        vga_red_o   <= vga_rgb(7 downto 5) & vga_rgb(7 downto 5) & vga_rgb(7 downto 6);
        vga_green_o <= vga_rgb(4 downto 2) & vga_rgb(4 downto 2) & vga_rgb(4 downto 3);
        vga_blue_o  <= vga_rgb(1 downto 0) & vga_rgb(1 downto 0) & vga_rgb(1 downto 0) & vga_rgb(1 downto 0);
      end if;
    end if;
  end process vga_proc;

  oddr_inst : component oddr
    port map (
      c  => vga_clk_i,
      ce => '1',
      d1 => '1',
      d2 => '0',
      r  => '0',
      s  => '0',
      q  => vdac_clk_o
    ); -- oddr_inst : component oddr

  vdac_blank_n_o <= '1';
  vdac_psave_n_o <= '1';
  vdac_sync_n_o  <= '0';

end architecture synthesis;

