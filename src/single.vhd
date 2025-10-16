library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity single is
  generic (
    G_ACCURACY  : natural;
    G_ADDR_BITS : natural;
    G_GRID_SIZE : natural
  );
  port (
    clk_i         : in    std_logic;
    rst_i         : in    std_logic;
    --
    coef_e_i      : in    ufixed(3 downto -G_ACCURACY);  -- [0, 16[
    coef_n_i      : in    ufixed(3 downto -G_ACCURACY);  -- [0, 16[
    --
    ready_o       : out   std_logic;
    valid_i       : in    std_logic;
    pos_x_i       : in    unsigned(G_ADDR_BITS - 1 downto 0);
    pos_y_i       : in    unsigned(G_ADDR_BITS - 1 downto 0);
    random_i      : in    ufixed(-1 downto -G_ACCURACY); -- [0, 1[
    --
    ram_addr_o    : out   std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
    ram_wr_data_o : out   std_logic;
    ram_rd_data_i : in    std_logic;
    ram_wr_en_o   : out   std_logic
  );
end entity single;

architecture synthesis of single is

  alias  ram_addr_x_o : std_logic_vector(G_ADDR_BITS - 1 downto 0) is ram_addr_o(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS);
  alias  ram_addr_y_o : std_logic_vector(G_ADDR_BITS - 1 downto 0) is ram_addr_o(G_ADDR_BITS - 1 downto 0);

  type   state_type is (
    IDLE_ST, STEP1_ST, STEP2_ST, STEP3_ST, STEP4_ST,
    STEP5_ST, STEP6_ST, STEP7_ST, STEP8_ST, STEP9_ST, STEP10_ST, STEP11_ST, STEP12_ST,
    STEP13_ST
  );
  signal state : state_type                                := IDLE_ST;

  signal pos_x        : unsigned(G_ADDR_BITS - 1 downto 0);
  signal pos_y        : unsigned(G_ADDR_BITS - 1 downto 0);
  signal random       : ufixed(-1 downto -G_ACCURACY); -- [0, 1[
  signal neighbor_cnt : natural range 0 to 4;

  signal cell  : std_logic;
  signal valid : std_logic;

  signal prob_valid         : std_logic;
  signal prob_numerator     : ufixed(7 downto -G_ACCURACY);
  signal prob_denominator   : ufixed(7 downto -G_ACCURACY);
  signal prob_numerator_d   : ufixed(7 downto -G_ACCURACY) := (others => '0');
  signal prob_denominator_d : ufixed(7 downto -G_ACCURACY);

  signal mult_tmp       : ufixed(7 downto -2 * G_ACCURACY);
  signal mult_tmp_d     : ufixed(7 downto -2 * G_ACCURACY);
  signal mult_numerator : ufixed(7 downto -G_ACCURACY)     := (others => '0');
  signal update         : std_logic;

begin

  ready_o <= '1' when state = IDLE_ST else
             '0';

  state_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      ram_wr_en_o <= '0';
      valid       <= '0';
      update      <= '1' when mult_numerator < prob_numerator_d else '0';

      case state is

        when IDLE_ST =>
          if valid_i = '1' then
            pos_x        <= pos_x_i;
            pos_y        <= pos_y_i;
            random       <= random_i;
            neighbor_cnt <= 0;

            -- Read from site
            ram_addr_x_o <= std_logic_vector(pos_x_i);
            ram_addr_y_o <= std_logic_vector(pos_y_i);
            ram_wr_en_o  <= '0';
            state        <= STEP1_ST;
          end if;

        when STEP1_ST =>
          -- Read from site to the right
          if pos_x < G_GRID_SIZE - 1 then
            ram_addr_x_o <= std_logic_vector(pos_x + 1);
          else
            ram_addr_x_o <= (others => '0');
          end if;
          ram_addr_y_o <= std_logic_vector(pos_y);
          ram_wr_en_o  <= '0';
          state        <= STEP2_ST;

        when STEP2_ST =>
          -- Read from site to the left
          if pos_x > 0 then
            ram_addr_x_o <= std_logic_vector(pos_x - 1);
          else
            ram_addr_x_o <= std_logic_vector(to_unsigned(G_GRID_SIZE - 1, G_ADDR_BITS));
          end if;
          ram_addr_y_o <= std_logic_vector(pos_y);
          ram_wr_en_o  <= '0';
          state        <= STEP3_ST;

        when STEP3_ST =>
          cell         <= ram_rd_data_i;
          -- Read from site below
          ram_addr_x_o <= std_logic_vector(pos_x);
          if pos_y < G_GRID_SIZE - 1 then
            ram_addr_y_o <= std_logic_vector(pos_y + 1);
          else
            ram_addr_y_o <= (others => '0');
          end if;
          ram_wr_en_o <= '0';
          state       <= STEP4_ST;

        when STEP4_ST =>
          if ram_rd_data_i = '1' then
            neighbor_cnt <= neighbor_cnt + 1;
          end if;
          -- Read from site above
          ram_addr_x_o <= std_logic_vector(pos_x);
          if pos_y > 0 then
            ram_addr_y_o <= std_logic_vector(pos_y - 1);
          else
            ram_addr_y_o <= std_logic_vector(to_unsigned(G_GRID_SIZE - 1, G_ADDR_BITS));
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
          state <= STEP7_ST;

        when STEP7_ST =>
          if ram_rd_data_i = '1' then
            neighbor_cnt <= neighbor_cnt + 1;
          end if;
          valid <= '1';
          state <= STEP8_ST;

        when STEP8_ST =>
          if prob_valid = '1' then
            prob_numerator_d   <= prob_numerator;
            prob_denominator_d <= prob_denominator;
            state              <= STEP9_ST;
          end if;

        when STEP9_ST =>
          mult_tmp <= random * prob_denominator_d;
          state    <= STEP10_ST;

        when STEP10_ST =>
          mult_tmp_d <= mult_tmp;
          state      <= STEP11_ST;

        when STEP11_ST =>
          mult_numerator <= resize(mult_tmp_d, prob_numerator_d);
          state          <= STEP12_ST;

        when STEP12_ST =>
          state <= STEP13_ST;

        when STEP13_ST =>
          if update then
            ram_addr_x_o  <= std_logic_vector(pos_x);
            ram_addr_y_o  <= std_logic_vector(pos_y);
            ram_wr_data_o <= not cell;
            ram_wr_en_o   <= '1';
          end if;
          state <= IDLE_ST;

      end case;

      if rst_i = '1' then
        state       <= IDLE_ST;
        ram_addr_o  <= (others => '0');
        ram_wr_en_o <= '0';
      end if;
    end if;
  end process state_proc;

  calc_prob_inst : entity work.calc_prob
    generic map (
      G_ACCURACY => G_ACCURACY
    )
    port map (
      clk_i              => clk_i,
      rst_i              => rst_i,
      coef_e_i           => coef_e_i,
      coef_n_i           => coef_n_i,
      neighbor_cnt_i     => neighbor_cnt,
      cell_i             => cell,
      valid_i            => valid,
      prob_numerator_o   => prob_numerator,
      prob_denominator_o => prob_denominator,
      valid_o            => prob_valid
    ); -- calc_prob_inst : entity work.calc_prob

end architecture synthesis;

