-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
--
-- Description: This module performs a table lookup to calculate the
-- exp function.
--
-- The input is interpreted as a value between 0 and 1.
-- The output is a value between 0 and 1.
--
-- The actual function calculated is y = 0.5^x - 1.
-- The MSB of exp_o will always be 1.
--
-- Latency is 1 clock cycle.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;

entity exp_rom is
  generic (
    G_ADDR_SIZE : natural;
    G_DATA_SIZE : natural
  );
  port (
    clk_i  : in    std_logic;
    addr_i : in    std_logic_vector(G_ADDR_SIZE - 1 downto 0);
    data_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
  );
end entity exp_rom;

architecture synthesis of exp_rom is

  constant C_SIZE : natural := 2 ** G_ADDR_SIZE;

  type     mem_type is array (0 to C_SIZE - 1) of std_logic_vector(G_DATA_SIZE - 1 downto 0);

  impure function initrom return mem_type is
    constant C_SCALE_X : real     := real(C_SIZE);
    constant C_SCALE_Y : real     := 2048.0;
    variable x_v       : real;
    variable y_v       : real;
    variable int_v     : integer;
    variable rom_v     : mem_type := (others => (others => '0'));
  begin
    --
    for i in 0 to C_SIZE - 1 loop
      x_v      := real(i + 1) / C_SCALE_X;  -- Adding one ensures the exp is never one.
      y_v      := exp(x_v * log(0.5));
      int_v    := integer(y_v * C_SCALE_Y); -- Rounding is automatic.
      rom_v(i) := to_stdlogicvector(int_v, G_DATA_SIZE);
    end loop;

    return rom_v;
  end function initrom;

  signal   mem : mem_type   := initrom;

begin

  -- Read from ROM
  read_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      data_o <= mem(to_integer(addr_i));
    end if;
  end process read_proc;

end architecture synthesis;

