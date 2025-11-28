-- CLOCK_DIVIDER.vhd
-- Asumsi Clock Input CLK_IN = 50 MHz, Target CLK_PIXEL = 25 MHz
-- Dibutuhkan pembagi N = 50/25 = 2.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CLOCK_DIVIDER is
    port (
        CLK_IN    : in  std_logic;
        RESET     : in  std_logic;
        CLK_PIXEL : out std_logic
    );
end CLOCK_DIVIDER;

architecture Behavioral of CLOCK_DIVIDER is
    signal clk_div_reg : std_logic := '0';
    -- Nilai COUNTER_MAX adalah N/2 - 1, (2/2) - 1 = 0
    constant N_DIVIDER : integer := 1; 
begin
    process(CLK_IN, RESET)
    begin
        if RESET = '1' then
            clk_div_reg <= '0';
        elsif rising_edge(CLK_IN) then
            -- Counter sederhana (bukan counter sejati, hanya toggle flip-flop)
            clk_div_reg <= not clk_div_reg; 
        end if;
    end process;
    
    CLK_PIXEL <= clk_div_reg;

end Behavioral;


-- VGA_CONTROLLER.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_CONTROLLER is
    port (
        CLK_PIXEL : in  std_logic;
        RESET     : in  std_logic;
        
        -- Sinyal Output ke Monitor
        HSYNC     : out std_logic;
        VSYNC     : out std_logic;
        VIDEO_ON  : out std_logic; -- Sinyal Piksel Aktif
        
        -- Posisi Piksel Output ke Data Generator
        H_COUNT   : out integer range 0 to 799;
        V_COUNT   : out integer range 0 to 524
    );
end VGA_CONTROLLER;

architecture Behavioral of VGA_CONTROLLER is
    -- Konstanta Timing (Disesuaikan dengan tabel di atas)
    constant H_DISPLAY      : integer := 640;
    constant H_FP           : integer := 640 + 16; -- Front Porch End
    constant H_SP           : integer := H_FP + 96; -- Sync Pulse End
    constant H_BP           : integer := H_SP + 48; -- Back Porch End (H_TOTAL - 1)
    constant H_TOTAL        : integer := 800;

    constant V_DISPLAY      : integer := 480;
    constant V_FP           : integer := 480 + 10; -- Front Porch End
    constant V_SP           : integer := V_FP + 2; -- Sync Pulse End
    constant V_BP           : integer := V_SP + 33; -- Back Porch End (V_TOTAL - 1)
    constant V_TOTAL        : integer := 525;

    signal h_counter : integer range 0 to H_TOTAL-1 := 0;
    signal v_counter : integer range 0 to V_TOTAL-1 := 0;
begin
    process(CLK_PIXEL, RESET)
    begin
        if RESET = '1' then
            h_counter <= 0;
            v_counter <= 0;
        elsif rising_edge(CLK_PIXEL) then
            -- Penghitung Horizontal (Per Baris)
            if h_counter < H_TOTAL - 1 then
                h_counter <= h_counter + 1;
            else
                h_counter <= 0;
                -- Penghitung Vertikal (Per Frame)
                if v_counter < V_TOTAL - 1 then
                    v_counter <= v_counter + 1;
                else
                    v_counter <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Logika Sinkronisasi dan Piksel Aktif
    HSYNC <= '0' when (h_counter >= H_FP) and (h_counter < H_SP) else '1';
    VSYNC <= '0' when (v_counter >= V_FP) and (v_counter < V_SP) else '1';
    
    VIDEO_ON <= '1' when (h_counter < H_DISPLAY) and (v_counter < V_DISPLAY) else '0';
    
    -- Output Penghitung
    H_COUNT <= h_counter;
    V_COUNT <= v_counter;

end Behavioral;


-- VIDEO_DATA_GENERATOR.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VIDEO_DATA_GENERATOR is
    port (
        CLK_PIXEL : in  std_logic;
        VIDEO_ON  : in  std_logic;
        H_COUNT   : in  integer range 0 to 799;
        V_COUNT   : in  integer range 0 to 524;
        
        -- Sinyal Output Warna (misalnya 4 bit per warna)
        RED       : out std_logic_vector(3 downto 0);
        GREEN     : out std_logic_vector(3 downto 0);
        BLUE      : out std_logic_vector(3 downto 0)
    );
end VIDEO_DATA_GENERATOR;

architecture Behavioral of VIDEO_DATA_GENERATOR is
begin
    process(CLK_PIXEL)
    begin
        if rising_edge(CLK_PIXEL) then
            if VIDEO_ON = '1' then
                -- Logika Tampilan (Ganti ini dengan Pembacaan Frame Buffer/RAM)
                -- Contoh sederhana: Membuat garis-garis pelangi
                if V_COUNT < 120 then
                    -- Merah Penuh
                    RED   <= "1111"; GREEN <= "0000"; BLUE  <= "0000";
                elsif V_COUNT < 240 then
                    -- Hijau Penuh
                    RED   <= "0000"; GREEN <= "1111"; BLUE  <= "0000";
                elsif V_COUNT < 360 then
                    -- Biru Penuh
                    RED   <= "0000"; GREEN <= "0000"; BLUE  <= "1111";
                else
                    -- Putih
                    RED   <= "1111"; GREEN <= "1111"; BLUE  <= "1111";
                end if;
                
                -- *Untuk proyek 'Simulasi File Video', Anda perlu mengimplementasikan:*
                -- 1. Sebuah RAM (Frame Buffer) yang menyimpan data piksel Anda.
                -- 2. Logika untuk membaca RAM pada alamat yang dihitung dari (H_COUNT, V_COUNT)
                -- 3. Logika untuk memuat (load) data file video Anda ke RAM ini saat inisialisasi atau dari sumber eksternal.
            else
                -- Selama Blanking Period, output warna harus "0000" (Hitam)
                RED   <= "0000"; 
                GREEN <= "0000"; 
                BLUE  <= "0000";
            end if;
        end if;
    end process;
end Behavioral;