draw_set_valign(fa_top);
draw_set_halign(fa_left);
var camera_data = camera.get_data("frametimes");
draw_text_color(12, 12, $"FPS: {fps}\nResolution: {Camera.DISPLAY_WIDTH}x{Camera.DISPLAY_HEIGHT}" + 
						$"\nGBuffer vRAM: {string(camera.get_vram_usage() / 1024 / 1024)}MB" + 
						$"\nGbuffer Frametimes:\n  GBuffer: {camera_data.gbuffer}\n  Lighting: {camera_data.lighting}\n  PPFX: {camera_data.ppfx}",
						c_white, c_white, c_white, c_white, 1.0);