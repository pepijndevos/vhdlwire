library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity askunpack is
  generic (
    divider : natural := 0
  );
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    input : in std_logic_vector(7 downto 0);
    input_ready : in std_logic;
    new_frame : in std_logic;
    output : out std_logic_vector(7 downto 0);
    output_ready : out std_logic
  );
end askunpack;

architecture behavioral of askunpack is
  constant MAX_PAYLOAD_LEN : natural := 67;
  type msgstatetype is (IDLE, LENGTH, HEADER, DATA, CRC);
  signal msgstate : msgstatetype;
  signal msglen : integer range 0 to MAX_PAYLOAD_LEN;
  signal msgcounter : integer range 0 to MAX_PAYLOAD_LEN;
begin

  process(clk, rst_n)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        msgstate <= IDLE;
        output <= (others => '0');
        output_ready <= '0';
      else
        output_ready <= '0';
        case msgstate is
          when IDLE =>
            if new_frame = '1' then
              msgstate <= LENGTH;
            end if; -- new frame
          when LENGTH =>
            if input_ready = '1' then
              msglen <= to_integer(unsigned(input));
              msgstate <= HEADER;
              msgcounter <= 3;
            end if; -- data ready
          when HEADER =>
            if input_ready = '1' then
              if msgcounter > 0 then
                msgcounter <= msgcounter-1;
              else
                msgstate <= DATA;
                msgcounter <= msglen-8;
              end if; -- msgcounter
            end if; -- data ready
          when DATA =>
            if input_ready = '1' then
              output <= input;
              output_ready <= '1';
              if msgcounter > 0 then
                msgcounter <= msgcounter-1;
              else
                msgstate <= CRC;
                msgcounter <= 1;
              end if; -- msgcounter
            end if; -- data ready
          when CRC =>
            if input_ready = '1' then
              -- TODO check CRC
              if msgcounter > 0 then
                msgcounter <= msgcounter-1;
              else
                msgstate <= IDLE;
              end if; -- msgcounter
            end if; -- data ready
        end case; -- case msgstate
        --output_ready <= input_ready;
        --output <= input;
      end if; -- rst
    end if; -- clk
  end process;

end behavioral;
