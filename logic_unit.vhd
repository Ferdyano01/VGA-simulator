library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity logic_unit is
    generic (
        H_TOTAL : integer := 800;
        V_TOTAL : integer := 525
    );
    port (
        clock : in std_logic;
        reset : in std_logic;

        vga_r    : out std_logic_vector(3 downto 0);
        vga_g    : out std_logic_vector(3 downto 0);
        vga_b    : out std_logic_vector(3 downto 0);
        vga_hs   : out std_logic;
        vga_vs   : out std_logic
    );
end entity;

architecture Behavioral of logic_unit is

    signal pixel_clk : std_logic := '0';
    signal x_pos    : integer range 0 to H_TOTAL - 1;
    signal y_pos    : integer range 0 to V_TOTAL - 1;
    signal video_on : std_logic;
    signal v_sync   : std_logic;

    signal current_frame : integer range 0 to 200 := 0;
    signal rom_address   : integer range 0 to 614399;
    signal rom_address_vec : std_logic_vector(19 downto 0);
    signal rom_data      : std_logic_vector(0 downto 0);

    constant IMG_W : integer := 64;
    constant IMG_H : integer := 48;
    constant MAX_FRAME : integer := 200;

    component VGA is 
        port (
            clock_in : in std_logic;
            reset_n  : in std_logic;
            h_output : out std_logic;
            v_output : out std_logic;
            x_out    : out integer range 0 to H_TOTAL - 1;
            y_out    : out integer range 0 to V_TOTAL - 1;
            video_on : out std_logic
        );
    end component;

    -- Xilinx IP Component Declaration
    COMPONENT bad_apple_rom IS
        PORT (
            clka  : IN STD_LOGIC;
            -- NEW: Add Write Enable and Data In ports
            wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            addra : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
            dina  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            douta : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
        );
    END COMPONENT;

begin

    -- Clock Divider
    process(clock)
    begin
        if rising_edge(clock) then
            pixel_clk <= not pixel_clk; -- Simple flip-flop divides by 2
        end if;
    end process;

    vga_inst : VGA
    port map (
        clock_in => pixel_clk,
        reset_n  => reset,
        h_output => VGA_HS,
        v_output => v_sync,
        x_out    => x_pos, 
        y_out    => y_pos,
        video_on => video_on
    );

    rom_address_vec <= std_logic_vector(to_unsigned(rom_address, 20));
    -- Connect to the ROM Component
    rom_inst : bad_apple_rom
    PORT MAP (
        wea   => "0",
        clka  => pixel_clk,
        addra => rom_address_vec,
        dina   => "0",
        douta => rom_data
    );

    vga_vs <= v_sync;

    -- Frame Counter
    process(v_sync, reset)
    begin
        if reset = '0' then
            current_frame <= 0;
        elsif rising_edge(v_sync) then
            if current_frame < MAX_FRAME - 1 then
                current_frame <= current_frame + 1;
            else
                current_frame <= 0;
            end if;
        end if;
    end process;

    -- ROM
    rom_address <= (current_frame * (IMG_W * IMG_H)) + 
                    ((y_pos / 10) * IMG_W) + (x_pos / 10);

    -- Color Output
    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if video_on = '1' then
                if x_pos < 640 and y_pos < 480 then
                    if rom_data(0) = '1' then
                        -- white
                        vga_r <= "1111";
                        vga_g <= "1111";
                        vga_b <= "1111"; 
                    else
                        -- black
                        vga_r <= "0000";
                        vga_g <= "0000";
                        vga_b <= "0000";
                    end if; 
                else
                    vga_r <= "0000";
                    vga_g <= "0000";
                    vga_b <= "0000";
                end if;
            end if;
        end if;
    end process;

end Behavioral;