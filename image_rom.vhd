library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity image_rom is
    generic (
        FILENAME : string;
        WORDS    : integer
    );
    port (
        clk         : in  std_logic;
        address     : in  std_logic_vector(21 downto 0);
        data_out    : out std_logic_vector(11 downto 0)
    );
end image_rom;

architecture behavioral of image_rom is
    type memory_array is array (0 to WORDS-1) of std_logic_vector(11 downto 0);
    
    impure function init_ram_from_file(ram_filename : in string) return memory_array is
        file text_file : text open read_mode is ram_filename;
        variable text_line : line;
        variable ram_content : memory_array;
        variable temp_hex : std_logic_vector(11 downto 0);
    begin
        for i in 0 to WORDS-1 loop
            if (not endfile(text_file)) then
                readline(text_file, text_line);
                hread(text_line, temp_hex);
                ram_content(i) := temp_hex;
            else
                ram_content(i) := (others => '0'); -- Fill rest with black if file is short
            end if;
        end loop;
        return ram_content;
    end function;

    -- Create Memory Array
    signal ram : memory_array := init_ram_from_file(FILENAME);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Standard synchronous read
            -- If address is out of bounds, return 0
            if (to_integer(unsigned(address)) < WORDS) then
                data_out <= ram(to_integer(unsigned(address)));
            else
                data_out <= (others => '0');
            end if;
        end if;
    end process;

end behavioral;