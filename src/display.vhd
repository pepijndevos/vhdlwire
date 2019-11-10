library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    h_sync : out std_logic;
    v_sync : out std_logic;
    disp_ena : out std_logic;
    vramaddress : out std_logic_vector(10 downto 0);
    char : in std_logic_vector(7 downto 0);
    pixel : out std_logic
  );
end display;

architecture behavior of display is
  signal column : integer;
  signal row : integer;
  signal col2x : unsigned(10 downto 0);
  signal col2xt1 : unsigned(10 downto 0);
  signal col2xt2 : unsigned(10 downto 0);
  signal row2x : unsigned(10 downto 0);
  signal ucol : unsigned(10 downto 0);
  signal ucolt1 : unsigned(10 downto 0);
  signal ucolt2 : unsigned(10 downto 0);
  signal urow : unsigned(10 downto 0);
  signal coladdr : unsigned(10 downto 0);
  signal rowaddr : unsigned(10 downto 0);
  signal row40x : unsigned(10 downto 0);
  signal tileaddress : std_logic_vector(10 downto 0);
  signal char_row : std_logic_vector(7 downto 0);
  signal disp_ena_sig : std_logic;

component tilerom
  port (
      clk : in std_logic;
      oen_n : in std_logic;
      address : in std_logic_vector(10 downto 0);
      data_out : out std_logic_vector(7 downto 0)
);
end component;

COMPONENT vga_controller
	PORT(
		pixel_clk	:	IN		STD_LOGIC;	--pixel clock at frequency of VGA mode being used
		reset_n		:	IN		STD_LOGIC;	--active low asycnchronous reset
		h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
		v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
		disp_ena		:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		column		:	OUT	INTEGER;		--horizontal pixel coordinate
		row			:	OUT	INTEGER;		--vertical pixel coordinate
		n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
		n_sync		:	OUT	STD_LOGIC); --sync-on-green output to DAC
END COMPONENT;

begin

  disp: vga_controller port map (
		pixel_clk => clk,
		reset_n => rst_n,
		h_sync => h_sync,
		v_sync => v_sync,
		disp_ena => disp_ena_sig,
		column => column,
		row => row,
		n_blank => open,
		n_sync => open
  );

  -- t-2
  -- 8x8 bitmap is upscaled 2x
  -- 800/16=50
  -- 480/16=30
  -- tile size = 8x8
  -- two chars per word
  -- (row2x/8)*50 + col2x/8
  ucol <= to_unsigned(column, 11);
  ucolt1 <= to_unsigned(column+1, 11);
  ucolt2 <= to_unsigned(column+2, 11);
  urow <= to_unsigned(row, 11);
  col2x <= shift_right(ucol, 1);
  col2xt1 <= shift_right(ucolt1, 1);
  col2xt2 <= shift_right(ucolt2, 1);
  row2x <= shift_right(urow, 1);
  rowaddr <= shift_right(row2x,3); --/8
  coladdr <= shift_right(col2xt2, 3); --/8
  -- x*50 = (x * 2) + (x * 16) + (x * 32) = (x << 1) + (x << 4) + (x << 5)
  row40x <= resize(shift_left(rowaddr, 1) + shift_left(rowaddr, 4) + shift_left(rowaddr, 5), 11);
  vramaddress <= std_logic_vector(row40x + coladdr);

  -- t-1
  -- col2x(2 downto 0) = char col
  -- row(2 downto 0) = char row
  tileaddress <= char & std_logic_vector(row2x(2 downto 0));

  rom: tilerom port map (
    clk => clk,
    oen_n => '0',
    address => tileaddress,
    data_out => char_row
  );
  -- t-0
  pixel <= not char_row(to_integer(col2x(2 downto 0))) when disp_ena_sig = '1' else '0';
  disp_ena <= disp_ena_sig;

end;
