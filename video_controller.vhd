library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_controller is
    generic (
        IMG_W : integer := 64;
        IMG_H : integer := 48
    );
    port (
        pixel_clk       : in std_logic;
        reset           : in std_logic;

        x_pos           : in integer;
        y_pos           : in integer;
        video_on        : in std_logic;

        current_frame   : in integer;

        mem_address_out : out std_logic_vector(21 downto 0);
        mem_data_in     : in  std_logic_vector(11 downto 0);

        rgb_out         : out std_logic_vector(11 downto 0)
    );
end entity;

architecture Behavioral of video_controller is

    signal rom_address : integer range 0 to 1048575;
    signal pixel_data : std_logic_vector(11 downto 0);


begin
    
    -- Address Calculation
    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if video_on = '1' then
                if (x_pos < IMG_W*10) and (y_pos < IMG_H*10) then
                    rom_address <= (current_frame * (IMG_W * IMG_H)) +
                                ((y_pos / 10) * IMG_W) + (x_pos / 10);
                end if;
            end if;
        end if;
    end process;

    -- Memory Out
    mem_address_out <= std_logic_vector(to_unsigned(rom_address, 22));

    -- Output
    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            -- Reset
            rgb_out <= (others => '0');

            if video_on = '1' then
                -- If within video scale
                if (x_pos < (IMG_W * 10)) and (y_pos < (IMG_H * 10)) then
                    pixel_data <= mem_data_in;
                    rgb_out <= pixel_data;
                end if;
            end if;
        end if;
    end process;


end Behavioral;
