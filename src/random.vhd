library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;

entity random is
  generic (
    G_SEED : std_logic_vector(63 downto 0) := (others => '0')
  );
  port (
    clk_i    : in    std_logic;
    rst_i    : in    std_logic;
    update_i : in    std_logic;
    output_o : out   std_logic_vector(63 downto 0)
  );
end entity random;

architecture synthesis of random is

  pure function reverse (
    arg : std_logic_vector
  ) return std_logic_vector is
    variable res_v : std_logic_vector(arg'range);
  begin
    --
    for i in arg'low to arg'high loop
      res_v(arg'high - i) := arg(i);
    end loop;

    return res_v;
  end function reverse;

  signal random1_s : std_logic_vector(63 downto 0);
  signal random2_s : std_logic_vector(63 downto 0);

begin

  lfsr1_inst : entity work.lfsr
    generic map (
      G_SEED  => G_SEED,
      G_WIDTH => 64,
      G_TAPS  => X"80000000000019E2" -- See https://users.ece.cmu.edu/~koopman/lfsr/64.txt
    )
    port map (
      clk_i      => clk_i,
      rst_i      => rst_i,
      update_i   => update_i,
      load_i     => '0',
      load_val_i => (others => '1'),
      output_o   => random1_s
    ); -- lfsr1_inst

  lfsr2_inst : entity work.lfsr
    generic map (
      G_SEED  => not G_SEED,
      G_WIDTH => 64,
      G_TAPS  => X"80000000000011E5" -- See https://users.ece.cmu.edu/~koopman/lfsr/64.txt
    )
    port map (
      clk_i      => clk_i,
      rst_i      => rst_i,
      update_i   => update_i,
      load_i     => '0',
      load_val_i => (others => '1'),
      output_o   => random2_s
    ); -- lfsr2_inst

  output_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      output_o <= random1_s + reverse(random2_s);
    end if;
  end process output_proc;

end architecture synthesis;

