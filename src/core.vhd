library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity core is
  generic (
    G_ACCURACY  : natural;
    G_ADDR_BITS : natural;
    G_GRID_SIZE : natural
  );
  port (
    clk_i          : in    std_logic;
    rst_i          : in    std_logic;
    valid_i        : in    std_logic;
    temperature_i  : in    ufixed(-1 downto -G_ACCURACY); -- [0, 1[
    neg_chem_pot_i : in    ufixed(1 downto -G_ACCURACY);  -- [0, 4[
    step_i         : in    std_logic;
    count_o        : out   natural;
    ram_addr_o     : out   std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
    ram_wr_data_o  : out   std_logic;
    ram_rd_data_i  : in    std_logic;
    ram_wr_en_o    : out   std_logic
  );
end entity core;

architecture synthesis of core is

  constant C_LN2 : real       := 0.6931471805599453;

  alias    ram_addr_x_o : std_logic_vector(G_ADDR_BITS - 1 downto 0) is ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS);
  alias    ram_addr_y_o : std_logic_vector(G_ADDR_BITS - 1 downto 0) is ram_addr_o(G_ADDR_BITS - 1 downto 0);

  type     state_type is (INIT_ST, IDLE_ST, BUSY_ST);
  signal   state : state_type := INIT_ST;

  signal   cnt : natural range 0 to 10;

  signal   temperature  : ufixed(-1 downto -G_ACCURACY);
  signal   neg_chem_pot : ufixed(1 downto -G_ACCURACY);

  signal   single_coef_e : ufixed(3 downto -G_ACCURACY);  -- [0, 16[
  signal   single_coef_n : ufixed(3 downto -G_ACCURACY);  -- [0, 16[
  signal   single_ready  : std_logic;
  signal   single_valid  : std_logic;
  signal   single_pos_x  : unsigned(G_ADDR_BITS - 1 downto 0);
  signal   single_pos_y  : unsigned(G_ADDR_BITS - 1 downto 0);
  signal   single_random : ufixed(-1 downto -G_ACCURACY); -- [0, 1[

  signal   rand_output   : std_logic_vector(63 downto 0);
  signal   rand_output_d : std_logic_vector(63 downto 0);

begin

  state_proc : process (clk_i)
    variable new_pos_x_v : unsigned(G_ADDR_BITS - 1 downto 0);
    variable new_pos_y_v : unsigned(G_ADDR_BITS - 1 downto 0);
    variable rand_x_v    : ufixed(-1 downto -G_ADDR_BITS);
    variable rand_y_v    : ufixed(-1 downto -G_ADDR_BITS);
  begin
    if rising_edge(clk_i) then
      rand_output_d <= rand_output;
      if single_ready = '1' then
        single_valid <= '0';
      end if;

      case state is

        when IDLE_ST =>
          if step_i = '1' and single_ready = '1' then
            count_o      <= count_o + 1;
            -- Get two random values in the range [0, 1[.
            rand_x_v     := to_ufixed(rand_output_d(G_ADDR_BITS + 20 - 1 downto 20), rand_x_v);
            rand_y_v     := to_ufixed(rand_output_d(G_ADDR_BITS + 10 - 1 downto 10), rand_y_v);

            -- Find random site
            new_pos_x_v  := unsigned(resize(rand_x_v * to_ufixed(G_GRID_SIZE, G_ADDR_BITS - 1, 0), G_ADDR_BITS - 1, 0));
            new_pos_y_v  := unsigned(resize(rand_y_v * to_ufixed(G_GRID_SIZE, G_ADDR_BITS - 1, 0), G_ADDR_BITS - 1, 0));

            single_pos_x <= new_pos_x_v;
            single_pos_y <= new_pos_y_v;

            single_valid <= '1';
            state        <= IDLE_ST;
          end if;

        when BUSY_ST =>
          null;

        when INIT_ST =>
          if cnt > 0 then
            cnt <= cnt - 1;
          else
            state <= IDLE_ST;
          end if;

      end case;

      if rst_i = '1' then
        single_valid <= '0';
        state        <= INIT_ST;
        cnt          <= 10;
        count_o      <= 0;
      end if;
    end if;
  end process state_proc;

  coef_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if valid_i = '1' then
        neg_chem_pot <= neg_chem_pot_i;
        temperature  <= temperature_i;
      end if;

      -- This generates a huge combinatorial network, but since this is not timing
      -- critical, a set_multicycle_path timing exception is used.
      single_coef_e <= resize(C_LN2 / temperature, single_coef_e);
      single_coef_n <= resize(single_coef_e * neg_chem_pot, single_coef_n);
    end if;
  end process coef_proc;

  random_inst : entity work.random
    generic map (
      G_SEED => X"DEADBEEFC007BABE"
    )
    port map (
      clk_i    => clk_i,
      rst_i    => rst_i,
      update_i => '1',
      output_o => rand_output
    ); -- random_inst : entity work.random

  single_inst : entity work.single
    generic map (
      G_ACCURACY  => G_ACCURACY,
      G_ADDR_BITS => G_ADDR_BITS,
      G_GRID_SIZE => G_GRID_SIZE
    )
    port map (
      clk_i         => clk_i,
      rst_i         => rst_i,
      coef_e_i      => single_coef_e,
      coef_n_i      => single_coef_n,
      ready_o       => single_ready,
      valid_i       => single_valid,
      pos_x_i       => single_pos_x,
      pos_y_i       => single_pos_y,
      random_i      => to_ufixed(rand_output_d(G_ACCURACY - 1 downto 0), - 1, - G_ACCURACY),
      ram_addr_o    => ram_addr_o,
      ram_wr_data_o => ram_wr_data_o,
      ram_rd_data_i => ram_rd_data_i,
      ram_wr_en_o   => ram_wr_en_o
    ); -- single_inst : entity work.single

end architecture synthesis;

