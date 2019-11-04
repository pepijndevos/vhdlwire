library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ported from https://github.com/PaulStoffregen/RadioHead/blob/master/RH_ASK.(h|cpp)

entity askrcv is
  generic (
    divider : natural := 0
  );
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    input : in std_logic;
    output : out std_logic_vector(7 downto 0);
    output_ready : out std_logic;
    new_frame : out std_logic
  );
end askrcv;

architecture behavioral of askrcv is
  signal ce_counter : natural := 0;
  signal ce : std_logic := '0'; -- clock enable
  signal last_input : std_logic := '0';
  signal bits : std_logic_vector(11 downto 0) := x"000";
  signal byte : std_logic_vector(7 downto 0) := x"00";
  signal active : boolean := false;
  signal bit_count : integer range 0 to 15 := 0;
  signal buf_len : integer range 0 to 15 := 0;
  signal count : natural := 0;
  signal integrator : integer range 0 to 15 := 0;
  signal pll_ramp : integer range 0 to 255 := 0;

  constant MAX_PAYLOAD_LEN : natural := 67;
  constant HEADER_LEN : natural := 4;
  constant MAX_MESSAGE_LEN : natural := (MAX_PAYLOAD_LEN - HEADER_LEN - 3);
  constant SAMPLES_PER_BIT : natural := 8;
  constant RAMP_LEN : natural := 160;
  constant RAMP_INC : natural := (RAMP_LEN/SAMPLES_PER_BIT);
  constant RAMP_TRANSITION : natural := RAMP_LEN/2;
  constant RAMP_ADJUST : natural := 9;
  constant RAMP_INC_RETARD : natural := (RAMP_INC-RAMP_ADJUST);
  constant RAMP_INC_ADVANCE : natural := (RAMP_INC+RAMP_ADJUST);
  constant PREAMBLE_LEN : natural := 8;
  constant START_SYMBOL : std_logic_vector(11 downto 0) := x"b38";

  function sixtofour(word : in std_logic_vector(5 downto 0))
    return std_logic_vector is
  begin
    case word is
      when "001101" => return x"0";
      when "001110" => return x"1";
      when "010011" => return x"2";
      when "010101" => return x"3";
      when "010110" => return x"4";
      when "011001" => return x"5";
      when "011010" => return x"6";
      when "011100" => return x"7";
      when "100011" => return x"8";
      when "100101" => return x"9";
      when "100110" => return x"a";
      when "101001" => return x"b";
      when "101010" => return x"c";
      when "101100" => return x"d";
      when "110010" => return x"e";
      when "110100" => return x"f";
      when others => return x"0";
    end case;
  end function sixtofour;
begin

  byte <= sixtofour(bits(5 downto 0)) & sixtofour(bits(11 downto 6));

  process(clk, rst_n)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        ce_counter <= 0;
      else
        if ce_counter = divider then
          ce_counter <= 0;
          ce <= '1';
        else
          ce <= '0';
          ce_counter <= ce_counter+1;
        end if;
      end if;
    end if;
  end process;

  process(clk, rst_n, ce)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        integrator <= 0;
        pll_ramp <= 0;
        last_input <= input;
        bits <= (others => '0');
        active <= false;
        bit_count <= 0;
        buf_len <= 0;
        count <= 0;
        output <= (others => '0');
        output_ready <= '0';
      elsif ce = '1' then
        output_ready <= '0'; -- set below
        new_frame <= '0'; -- set below
        if pll_ramp > RAMP_LEN then
          if input /= last_input then
            if pll_ramp < RAMP_TRANSITION then
              pll_ramp <= pll_ramp + RAMP_INC_RETARD - RAMP_LEN;
            else
              pll_ramp <= pll_ramp + RAMP_INC_ADVANCE - RAMP_LEN;
            end if;  -- ramp transition
          else
            pll_ramp <= pll_ramp + RAMP_INC - RAMP_LEN;
          end if; -- input /= last_input
        else
          if input /= last_input then
            if pll_ramp < RAMP_TRANSITION then
              pll_ramp <= pll_ramp + RAMP_INC_RETARD;
            else
              pll_ramp <= pll_ramp + RAMP_INC_ADVANCE;
            end if;  -- ramp transition
          else
            pll_ramp <= pll_ramp + RAMP_INC;
          end if; -- input /= last_input
        end if; -- pll_ram > RAMP_LEN
        integrator <= integrator + to_integer(unsigned'("" & input));
        last_input <= input;

        if pll_ramp > RAMP_LEN then
          if active then
            bit_count <= bit_count + 1;
            if bit_count >= 11 then
              if buf_len = 0 then
                count <= to_integer(unsigned(byte));
                -- TODO throw away invalid count?
              else
                output <= byte;
                output_ready <= '1';
                if buf_len >= count then
                  active <= false;
                end if;
              end if;
              buf_len <= buf_len + 1;
              bit_count <= 0;
            end if;
          elsif bits = START_SYMBOL then
            active <= true;
            bit_count <= 0;
            buf_len <= 0;
            new_frame <= '1';
          end if; -- active

          if integrator >= 5 then
            bits <= '1' & bits(11 downto 1);
          else
            bits <= '0' & bits(11 downto 1);
          end if; -- integrator >= 5
          integrator <= 0;
        end if; -- pll_ramp > RAMP_LEN
      end if; -- ce
    end if; -- rising_edge(clk)
  end process;

end behavioral;
