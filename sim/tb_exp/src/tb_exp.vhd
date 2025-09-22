library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity tb_exp is
  generic (
    G_ACCURACY : natural
  );
end entity tb_exp;

architecture simulation of tb_exp is

  signal running : std_logic                := '1';
  signal clk     : std_logic                := '1';
  signal rst     : std_logic                := '1';

  signal arg : sfixed(2 downto -G_ACCURACY) := (others => '0');
  signal res : ufixed(3 downto -G_ACCURACY);

begin

  clk <= running and not clk after 5 ns;
  rst <= '1', '0' after 100 ns;

  test_proc : process
    variable val_v     : std_logic_vector(2 + G_ACCURACY downto 0);
    variable exp_val_v : ufixed(3 downto -G_ACCURACY);
    variable diff_v    : unsigned(3 + G_ACCURACY downto 0);
  begin
    wait until rst = '0';
    wait until rising_edge(clk);

    report "Test started";

    for i in 0 to 2 ** (3 + G_ACCURACY) - 1 loop
      arg <= to_sfixed(std_logic_vector(to_signed(i - 2 ** (2 + G_ACCURACY), 3 + G_ACCURACY)), arg);
      wait until rising_edge(clk);

      for j in 1 to work.exp'latency loop
        wait until rising_edge(clk);
      end loop;

      exp_val_v := to_ufixed(exp(log(2.0) * to_real(arg)), res);
      if res /= exp_val_v then
        diff_v := unsigned(to_slv(exp_val_v)) - unsigned(to_slv(res));
        assert diff_v < 8
          report to_hstring(diff_v) & " :: " & to_string(arg) & "(" & to_string(to_real(arg)) & ")->"
                 & to_string(res) & "(" & to_string(to_real(res)) & "). "
                 & "exp=" & to_string(exp_val_v) & "(" & to_string(to_real(exp_val_v)) & ")";
      end if;
    end loop;

    report "Test finished";

    running <= '0';
    wait;
  end process test_proc;

  exp_inst : entity work.exp
    generic map (
      G_ACCURACY => G_ACCURACY
    )
    port map (
      clk_i => clk,
      arg_i => arg,
      res_o => res
    ); -- exp_inst : entity work.exp

end architecture simulation;

