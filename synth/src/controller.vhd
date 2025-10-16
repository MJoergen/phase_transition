library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity controller is
  generic (
    G_ACCURACY     : natural
  );
  port (
    clk_i          : in    std_logic;
    rst_i          : in    std_logic;
    key_valid_i    : in    std_logic;
    key_code_i     : in    integer range 0 to 79;
    step_o         : out   std_logic;
    valid_o        : out   std_logic;
    temperature_o  : out   ufixed(-1 downto -G_ACCURACY);
    neg_chem_pot_o : out   ufixed(1 downto -G_ACCURACY)
  );
end entity controller;

architecture synthesis of controller is

  -- Temperature is limited to the range [0, 1[.
  -- Chemical Potential is in the range ]-4, 0].
  --   Note: Only the absolute value is stored, i.e. in the range [0, 4[
  constant C_INITIAL_TEMPERATURE : real := 0.3;
  constant C_INITIAL_CHEM_POT    : real := -2.5;

  -- MEGA65 key codes that kb_key_num_i is using while
  -- kb_key_pressed_n_i is signalling (low active) which key is pressed
  constant C_M65_INS_DEL     : integer  := 0;
  constant C_M65_RETURN      : integer  := 1;
  constant C_M65_HORZ_CRSR   : integer  := 2;  -- means cursor right in C64 terminology
  constant C_M65_F7          : integer  := 3;
  constant C_M65_F1          : integer  := 4;
  constant C_M65_F3          : integer  := 5;
  constant C_M65_F5          : integer  := 6;
  constant C_M65_VERT_CRSR   : integer  := 7;  -- means cursor down in C64 terminology
  constant C_M65_3           : integer  := 8;
  constant C_M65_W           : integer  := 9;
  constant C_M65_A           : integer  := 10;
  constant C_M65_4           : integer  := 11;
  constant C_M65_Z           : integer  := 12;
  constant C_M65_S           : integer  := 13;
  constant C_M65_E           : integer  := 14;
  constant C_M65_LEFT_SHIFT  : integer  := 15;
  constant C_M65_5           : integer  := 16;
  constant C_M65_R           : integer  := 17;
  constant C_M65_D           : integer  := 18;
  constant C_M65_6           : integer  := 19;
  constant C_M65_C           : integer  := 20;
  constant C_M65_F           : integer  := 21;
  constant C_M65_T           : integer  := 22;
  constant C_M65_X           : integer  := 23;
  constant C_M65_7           : integer  := 24;
  constant C_M65_Y           : integer  := 25;
  constant C_M65_G           : integer  := 26;
  constant C_M65_8           : integer  := 27;
  constant C_M65_B           : integer  := 28;
  constant C_M65_H           : integer  := 29;
  constant C_M65_U           : integer  := 30;
  constant C_M65_V           : integer  := 31;
  constant C_M65_9           : integer  := 32;
  constant C_M65_I           : integer  := 33;
  constant C_M65_J           : integer  := 34;
  constant C_M65_0           : integer  := 35;
  constant C_M65_M           : integer  := 36;
  constant C_M65_K           : integer  := 37;
  constant C_M65_O           : integer  := 38;
  constant C_M65_N           : integer  := 39;
  constant C_M65_PLUS        : integer  := 40;
  constant C_M65_P           : integer  := 41;
  constant C_M65_L           : integer  := 42;
  constant C_M65_MINUS       : integer  := 43;
  constant C_M65_DOT         : integer  := 44;
  constant C_M65_COLON       : integer  := 45;
  constant C_M65_AT          : integer  := 46;
  constant C_M65_COMMA       : integer  := 47;
  constant C_M65_GBP         : integer  := 48;
  constant C_M65_ASTERISK    : integer  := 49;
  constant C_M65_SEMICOLON   : integer  := 50;
  constant C_M65_CLR_HOME    : integer  := 51;
  constant C_M65_RIGHT_SHIFT : integer  := 52;
  constant C_M65_EQUAL       : integer  := 53;
  constant C_M65_ARROW_UP    : integer  := 54; -- symbol, not cursor
  constant C_M65_SLASH       : integer  := 55;
  constant C_M65_1           : integer  := 56;
  constant C_M65_ARROW_LEFT  : integer  := 57; -- symbol, not cursor
  constant C_M65_CTRL        : integer  := 58;
  constant C_M65_2           : integer  := 59;
  constant C_M65_SPACE       : integer  := 60;
  constant C_M65_MEGA        : integer  := 61;
  constant C_M65_Q           : integer  := 62;
  constant C_M65_RUN_STOP    : integer  := 63;
  constant C_M65_NO_SCRL     : integer  := 64;
  constant C_M65_TAB         : integer  := 65;
  constant C_M65_ALT         : integer  := 66;
  constant C_M65_HELP        : integer  := 67;
  constant C_M65_F9          : integer  := 68;
  constant C_M65_F11         : integer  := 69;
  constant C_M65_F13         : integer  := 70;
  constant C_M65_ESC         : integer  := 71;
  constant C_M65_CAPSLOCK    : integer  := 72;
  constant C_M65_UP_CRSR     : integer  := 73; -- cursor up
  constant C_M65_LEFT_CRSR   : integer  := 74; -- cursor left
  constant C_M65_RESTORE     : integer  := 75;
  constant C_M65_NONE        : integer  := 79;

begin

  controller_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      step_o  <= '0';
      valid_o <= '0';
      if key_valid_i = '1' then

        case key_code_i is

          when C_M65_A =>
            if temperature_o > 0.15 then
              temperature_o <= resize(temperature_o - 0.1, temperature_o);
              valid_o       <= '1';
            end if;

          when C_M65_D =>
            if temperature_o < 0.95 then
              temperature_o <= resize(temperature_o + 0.1, temperature_o);
              valid_o       <= '1';
            end if;

          when C_M65_W =>
            if neg_chem_pot_o > 0.15 then
              neg_chem_pot_o <= resize(neg_chem_pot_o - 0.1, neg_chem_pot_o);
              valid_o        <= '1';
            end if;

          when C_M65_X =>
            if neg_chem_pot_o < 2.95 then
              neg_chem_pot_o <= resize(neg_chem_pot_o + 0.1, neg_chem_pot_o);
              valid_o        <= '1';
            end if;

          when C_M65_S =>
            step_o <= '1';

          when others =>
            null;

        end case;

      end if;

      if rst_i = '1' then
        temperature_o  <= to_ufixed(C_INITIAL_TEMPERATURE, -1, -G_ACCURACY);
        neg_chem_pot_o <= to_ufixed(-C_INITIAL_CHEM_POT, 1, -G_ACCURACY);
      end if;
    end if;
  end process controller_proc;

end architecture synthesis;

