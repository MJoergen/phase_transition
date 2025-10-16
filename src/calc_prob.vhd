library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

-- This calculates the value:
-- q = pow2(Coef_e*E_loss + Coef_n*N_loss)
-- where
-- E_loss = E_cur - E_new
-- N_loss = N_cur - N_new
-- coef_e is in range [0, 15[
-- coef_n is in range [0, 15[

entity calc_prob is
  generic (
    G_ACCURACY : natural
  );
  port (
    clk_i              : in    std_logic;
    rst_i              : in    std_logic;
    coef_e_i           : in    ufixed(3 downto -G_ACCURACY);
    coef_n_i           : in    ufixed(3 downto -G_ACCURACY);
    neighbor_cnt_i     : in    natural range 0 to 4;
    cell_i             : in    std_logic;
    valid_i            : in    std_logic;
    prob_numerator_o   : out   ufixed(7 downto -G_ACCURACY);
    prob_denominator_o : out   ufixed(7 downto -G_ACCURACY);
    valid_o            : out   std_logic
  );
  attribute latency : natural;
  attribute latency of calc_prob : entity is work.pow2'latency + 2;
end entity calc_prob;

architecture synthesis of calc_prob is

  constant C_ADDR_SIZE : natural                    := G_ACCURACY;
  constant C_DATA_SIZE : natural                    := G_ACCURACY;

  pure function energy_loss (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic
  ) return integer is
  begin
    if cell = '1' then
      return -neighbor_cnt;
    else
      return neighbor_cnt;
    end if;
  end function energy_loss;

  pure function number_loss (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic
  ) return integer is
  begin
    if cell = '1' then
      return 1;
    else
      return -1;
    end if;
  end function number_loss;

  -- This calculates:
  -- ln(q) = coef_e * E_loss + coef_n * N_loss.
  -- where E_loss and N_loss is calculated for the swap: cell -> not cell.

  pure function calc_lnq (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic;
    coef_e       : ufixed(3 downto -G_ACCURACY);
    coef_n       : ufixed(3 downto -G_ACCURACY)
  ) return sfixed is
    variable res_v  : sfixed(7 downto -G_ACCURACY);
    variable res2_v : sfixed(8 downto -G_ACCURACY);
  begin
    res_v := to_sfixed(coef_e * to_ufixed(neighbor_cnt, 2, 0));

    if cell = '0' then
      res2_v := res_v - to_sfixed(coef_n);
    else
      res2_v := to_sfixed(coef_n) - res_v;
    end if;

    return res2_v;
  end function calc_lnq;

  signal   coef_e : ufixed(3 downto -G_ACCURACY);
  signal   coef_n : ufixed(3 downto -G_ACCURACY);

  signal   valid : std_logic;
  signal   cell  : std_logic;

  signal   lnq       : sfixed(8 downto -G_ACCURACY) := (others => '0');
  signal   lnq_valid : std_logic;

  signal   pow2_arg : sfixed(4 downto -G_ACCURACY);
  signal   pow2_res : ufixed(7 downto -G_ACCURACY);

  signal   res : sfixed(7 downto -G_ACCURACY);

begin

  calc_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      coef_e <= coef_e_i;
      coef_n <= coef_n_i;
      valid  <= valid_i;

      if valid_i = '1' then
        res  <= to_sfixed(coef_e * to_ufixed(neighbor_cnt_i, 2, 0));
        cell <= cell_i;
      end if;

      if valid = '1' then
        if cell = '0' then
          lnq <= res - to_sfixed(coef_n);
        else
          lnq <= to_sfixed(coef_n) - res;
        end if;
      end if;
      lnq_valid <= valid;

      if rst_i = '1' then
        lnq_valid <= '0';
      end if;
    end if;
  end process calc_proc;

  pow2_arg <= resize(lnq, 4, -G_ACCURACY);

  pow2_inst : entity work.pow2
    generic map (
      G_ACCURACY => G_ACCURACY
    )
    port map (
      clk_i   => clk_i,
      rst_i   => rst_i,
      valid_i => lnq_valid,
      arg_i   => pow2_arg,
      valid_o => valid_o,
      res_o   => pow2_res
    ); -- pow2_inst : entity work.pow2

  prob_numerator_o   <= resize(pow2_res, prob_numerator_o);
  prob_denominator_o <= resize(prob_numerator_o + 1, prob_denominator_o);

end architecture synthesis;

