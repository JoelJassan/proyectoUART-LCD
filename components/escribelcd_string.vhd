library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity escribelcd_string is
	generic (
		longitud_cadena : integer := 16
	);

	port (
		clk, reset : in std_logic := '0';
		pantalla   : in string (1 to longitud_cadena);

		lcd_data                   : out std_logic_vector (7 downto 0);
		lcd_enable, lcd_rw, lcd_rs : out std_logic
	);
end escribelcd_string;

architecture a_escribelcd of escribelcd_string is
	type mef is (reset0, delay1, delay2, delay3, delay4, delay5, seteo, seteo1, on_off_control, reseteo, modoEntrada, escribe1c, escribe_next_c, fin);
begin

	process (clk, reset, pantalla) is
		variable estado            : mef;
		variable cnt               : integer := 1;
		variable pantalla_anterior : string (1 to longitud_cadena);
	begin
		-- el comentario de la derecha se referencia por la otra mef (when estado_de_la_izquierda a comentario_de_la_derecha)
		if (reset = '0') then
			estado := reset0; --(delay1)

		elsif (rising_edge(clk)) then
			case estado is
				when reset0 => estado := delay1;
					LCD_DATA   <= "00000001";
					LCD_ENABLE <= '0';
					LCD_RW     <= '0';
					LCD_RS     <= '0';
					cnt                   := 0;
				when delay1 => estado := seteo; --seteo del dysplay (delay1)
					LCD_ENABLE <= '1';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when seteo => estado := delay2; --wait hasta que clk=1 (seteo)
					LCD_DATA   <= "00111100";
					LCD_ENABLE <= '0';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when delay2 => estado := seteo1;--reseteo y borrado de la pantalla completa (delay2)
					LCD_ENABLE <= '1';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when seteo1 => estado := delay3;--wait hasta que clk=1 (seteo1)
					LCD_DATA   <= "00111100";
					LCD_ENABLE <= '0';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when delay3 => estado := on_off_control;--wait hasta que clk=1 (delay3)
					LCD_ENABLE <= '1';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when on_off_control => estado := delay4;--encendido y preparacion para mandar caracteres (on_off_ctrl)
					LCD_DATA   <= "00001100";
					LCD_ENABLE <= '0';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when delay4 => estado := reseteo;--wait hasta que clk=1 (delay4)
					LCD_ENABLE <= '1';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when reseteo => estado := delay5;
					LCD_DATA   <= "00000001";
					LCD_ENABLE <= '0';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when delay5 => estado := modoEntrada;
					LCD_ENABLE <= '1';
					LCD_RW     <= '0';
					LCD_RS     <= '0';

				when modoEntrada => estado := escribe1c;
					LCD_DATA   <= "00000111";
					LCD_ENABLE <= '0';
					LCD_RW     <= '0';
					LCD_RS     <= '0';
					cnt := cnt + 1;

					-- LOGICA DE ESCRITURA --------------------------------------------------------
				when escribe1c => estado := escribe_next_c;
					LCD_DATA <= std_logic_vector(to_unsigned (character'pos(pantalla(cnt)), 8));-- TRANSFORMO CADA ELEMENTO DEL STRING

					LCD_ENABLE <= '1';
					LCD_RW     <= '0';
					LCD_RS     <= '1';
					cnt := cnt + 1;

				when escribe_next_c =>
					if cnt = (pantalla'length) then
						estado            := fin;
						cnt               := 1;
						pantalla_anterior := pantalla;
					else
						estado := escribe1c;
						LCD_ENABLE <= '0';
						LCD_RW     <= '0';
						LCD_RS     <= '1';
					end if;
					-- LOGICA DE ESCRITURA --------------------------------------------------------

				when others =>
					if pantalla_anterior = pantalla then
						estado := fin;--estado de espera hasta que se presione reset nuevamente
					else
						estado := reset0;
					end if;
			end case;
		end if;
	end process;
end a_escribelcd;