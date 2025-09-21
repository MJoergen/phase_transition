-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
--
-- Description: This module calculates the function 2^x in two clock cycles.
-- * First cycle is a table lookup.
-- * Second cycle is a shift.
-- Both 'arg' and 'res' are in fixed point notation:
-- * 'arg' ranges from [-4; 4[.
-- * 'res' ranges from [0; 8[.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity exp is
  generic (
    G_ACCURACY : natural
  );
  port (
    clk_i : in    std_logic;
    arg_i : in    sfixed(2 downto -G_ACCURACY);
    res_o : out   ufixed(2 downto -G_ACCURACY)
  );
end entity exp;

architecture synthesis of exp is

  constant C_ADDR_SIZE : natural := G_ACCURACY;
  constant C_DATA_SIZE : natural := G_ACCURACY;

  signal   shift : natural range 0 to 7;

  signal   addr : std_logic_vector(C_ADDR_SIZE - 1 downto 0);
  signal   data : std_logic_vector(C_DATA_SIZE - 1 downto 0);

begin

  ------------------------------------
  -- First cycle: Table lookup
  ------------------------------------

  addr <= std_logic_vector(arg_i(-1 downto -G_ACCURACY));

  exp_rom_inst : entity work.exp_rom
    generic map (
      G_ADDR_SIZE => C_ADDR_SIZE,
      G_DATA_SIZE => C_DATA_SIZE
    )
    port map (
      clk_i  => clk_i,
      addr_i => addr,
      data_o => data
    ); -- exp_rom_inst : entity work.exp_rom

  first_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      shift <= to_integer(unsigned(arg_i(2 downto 0)));
    end if;
  end process first_proc;


  ------------------------------------
  -- Second cycle: Shift
  ------------------------------------

  second_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then

      case shift is

        when 0 =>
          res_o <= to_ufixed(data, 2, -G_ACCURACY);

        when others =>
          null;

      end case;

    end if;
  end process second_proc;

end architecture synthesis;

