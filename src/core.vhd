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
    step_i         : in    std_logic;
    temperature_i  : in    ufixed(-1 downto -G_ACCURACY);
    neg_chem_pot_i : in    ufixed(1 downto -G_ACCURACY);
    ram_addr_o     : out   std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
    ram_wr_data_o  : out   std_logic;
    ram_rd_data_i  : in    std_logic;
    ram_wr_en_o    : out   std_logic
  );
end entity core;

architecture synthesis of core is

  type   state_type is (INIT_ST, IDLE_ST, STEP1_ST, STEP2_ST, STEP3_ST, STEP4_ST, STEP5_ST, STEP6_ST, STEP7_ST, STEP8_ST, STEP9_ST);
  signal state : state_type := INIT_ST;

  signal cnt : natural range 0 to 10;

  signal pos_x : unsigned(G_ADDR_BITS - 1 downto 0);
  signal pos_y : unsigned(G_ADDR_BITS - 1 downto 0);

  signal neighbor_cnt       : natural range 0 to 4;
  signal cell               : std_logic;
  signal valid              : std_logic;
  signal prob_numerator     : std_logic_vector(G_ACCURACY - 1 downto 0);
  signal prob_denominator   : std_logic_vector(G_ACCURACY - 1 downto 0);
  signal prob_numerator_d   : std_logic_vector(G_ACCURACY - 1 downto 0);
  signal prob_denominator_d : std_logic_vector(G_ACCURACY - 1 downto 0);

  signal rand_output : std_logic_vector(63 downto 0);
  signal random_d    : std_logic_vector(15 downto 0);
  signal mult        : unsigned(15 downto 0);

  pure function mult_grid (
    r : unsigned(G_ADDR_BITS - 1 downto 0);
    m : unsigned(G_ADDR_BITS - 1 downto 0)
  ) return unsigned is
    variable tmp_v : unsigned(2 * G_ADDR_BITS - 1 downto 0);
  begin
    tmp_v := r * m;
    return tmp_v(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS);
  end function mult_grid;

  pure function mult_prob (
    r : unsigned(15 downto 0);
    m : unsigned(15 downto 0)
  ) return unsigned is
    variable tmp_v : unsigned(31 downto 0);
  begin
    tmp_v := r * m;
    return tmp_v(31 downto 16);
  end function mult_prob;

--  attribute mark_debug : string;
--  attribute mark_debug of step_i           : signal is "true";
--  attribute mark_debug of ram_addr_o       : signal is "true";
--  attribute mark_debug of ram_wr_data_o    : signal is "true";
--  attribute mark_debug of ram_rd_data_i    : signal is "true";
--  attribute mark_debug of ram_wr_en_o      : signal is "true";
--  attribute mark_debug of state            : signal is "true";
--  attribute mark_debug of cnt              : signal is "true";
--  attribute mark_debug of pos_x            : signal is "true";
--  attribute mark_debug of pos_y            : signal is "true";
--  attribute mark_debug of neighbor_cnt     : signal is "true";
--  attribute mark_debug of cell             : signal is "true";
--  attribute mark_debug of prob_numerator   : signal is "true";
--  attribute mark_debug of prob_denominator : signal is "true";
--  attribute mark_debug of rand_output      : signal is "true";

begin

  state_proc : process (clk_i)
    variable new_pos_x_v : unsigned(G_ADDR_BITS - 1 downto 0);
    variable new_pos_y_v : unsigned(G_ADDR_BITS - 1 downto 0);
  begin
    if rising_edge(clk_i) then
      ram_wr_en_o <= '0';
      valid       <= '0';

      case state is

        when IDLE_ST =>
          if step_i = '1' then
            -- Find random site
            new_pos_x_v                                        := mult_grid(unsigned(rand_output(G_ADDR_BITS + 40 - 1 downto 40)),
                                                                            to_unsigned(G_GRID_SIZE, G_ADDR_BITS));
            new_pos_y_v                                        := mult_grid(unsigned(rand_output(G_ADDR_BITS + 20 - 1 downto 20)),
                                                                            to_unsigned(G_GRID_SIZE, G_ADDR_BITS));
            pos_x                                              <= new_pos_x_v;
            pos_y                                              <= new_pos_y_v;

            neighbor_cnt                                       <= 0;

            -- Read from site
            ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(new_pos_x_v);
            ram_addr_o(G_ADDR_BITS - 1 downto 0)               <= std_logic_vector(new_pos_y_v);
            ram_wr_en_o                                        <= '0';
            state                                              <= STEP1_ST;
          end if;

        when STEP1_ST =>
          -- Read from site to the right
          if pos_x < G_GRID_SIZE - 1 then
            ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(pos_x + 1);
          else
            ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= (others => '0');
          end if;
          ram_addr_o(G_ADDR_BITS - 1 downto 0) <= std_logic_vector(pos_y);
          ram_wr_en_o                          <= '0';
          state                                <= STEP2_ST;

        when STEP2_ST =>
          cell <= ram_rd_data_i;
          -- Read from site to the left
          if pos_x > 0 then
            ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(pos_x - 1);
          else
            ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(to_unsigned(G_GRID_SIZE - 1, G_ADDR_BITS));
          end if;
          ram_addr_o(G_ADDR_BITS - 1 downto 0) <= std_logic_vector(pos_y);
          ram_wr_en_o                          <= '0';
          state                                <= STEP3_ST;

        when STEP3_ST =>
          if ram_rd_data_i = '1' then
            neighbor_cnt <= neighbor_cnt + 1;
          end if;
          -- Read from site below
          ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(pos_x);
          if pos_y < G_GRID_SIZE - 1 then
            ram_addr_o(G_ADDR_BITS - 1 downto 0) <= std_logic_vector(pos_y + 1);
          else
            ram_addr_o(G_ADDR_BITS - 1 downto 0) <= (others => '0');
          end if;
          ram_wr_en_o <= '0';
          state       <= STEP4_ST;

        when STEP4_ST =>
          if ram_rd_data_i = '1' then
            neighbor_cnt <= neighbor_cnt + 1;
          end if;
          -- Read from site above
          ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(pos_x);
          if pos_y > 0 then
            ram_addr_o(G_ADDR_BITS - 1 downto 0) <= std_logic_vector(pos_y - 1);
          else
            ram_addr_o(G_ADDR_BITS - 1 downto 0) <= std_logic_vector(to_unsigned(G_GRID_SIZE - 1, G_ADDR_BITS));
          end if;
          ram_wr_en_o <= '0';
          state       <= STEP5_ST;

        when STEP5_ST =>
          if ram_rd_data_i = '1' then
            neighbor_cnt <= neighbor_cnt + 1;
          end if;
          state <= STEP6_ST;

        when STEP6_ST =>
          if ram_rd_data_i = '1' then
            neighbor_cnt <= neighbor_cnt + 1;
          end if;
          valid <= '1';
          state <= STEP7_ST;

        when STEP7_ST =>
          random_d           <= rand_output(31 downto 16);
          prob_numerator_d   <= prob_numerator;
          prob_denominator_d <= prob_denominator;
          state              <= STEP8_ST;

        when STEP8_ST =>
          mult  <= mult_prob(unsigned(random_d), unsigned(prob_numerator_d));
          state <= STEP9_ST;

        when STEP9_ST =>
          if mult < unsigned(prob_denominator_d) then
            ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS) <= std_logic_vector(pos_x);
            ram_addr_o(G_ADDR_BITS - 1 downto 0)               <= std_logic_vector(pos_y);
            ram_wr_data_o                                      <= not cell;
            ram_wr_en_o                                        <= '1';
          end if;
          state <= IDLE_ST;

        when INIT_ST =>
          if cnt > 0 then
            cnt <= cnt - 1;
          else
            state <= IDLE_ST;
          end if;

      end case;

      if rst_i = '1' then
        state <= INIT_ST;
        cnt   <= 10;
      end if;
    end if;
  end process state_proc;

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

  calc_prob_inst : entity work.calc_prob
    generic map (
      G_ACCURACY => G_ACCURACY
    )
    port map (
      clk_i              => clk_i,
      rst_i              => rst_i,
      coef_e_i           => temperature_i,
      coef_n_i           => neg_chem_pot_i,
      neighbor_cnt_i     => neighbor_cnt,
      cell_i             => cell,
      valid_i            => valid,
      prob_numerator_o   => prob_numerator,
      prob_denominator_o => prob_denominator
    ); -- calc_prob_inst : entity work.calc_prob

end architecture synthesis;

