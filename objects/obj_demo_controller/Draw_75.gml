// Render 'group border' for light check boxes:
draw_set_alpha(0.8);
draw_rectangle_color(11, display_get_gui_height() - 37, 256 * 3 - 96, display_get_gui_height() - 11, c_gray, c_gray, c_gray, c_gray, true);
draw_rectangle_color(11, display_get_gui_height() - 37 - 36, 256 * 3 - 96, display_get_gui_height() - 11 - 36, c_gray, c_gray, c_gray, c_gray, true);
draw_set_alpha(1.0);

// Render axis display:
var cx = 12 + 48;
var cy = 256 + 64;
var length = 48;
var forward = vec(1, 0, 0);
var right = vec(0, 0, 1);
var up = vec(0, 1, 0);
var viewprojection = matrix_multiply(camera.eye_id.get_view_matrix(), camera.eye_id.get_projection_matrix());
forward = vec_set_length(matrix_multiply_vec(viewprojection, forward), length);
right = vec_set_length(matrix_multiply_vec(viewprojection, right), length);
up = vec_set_length(matrix_multiply_vec(viewprojection, up), length);

right.x = -right.x;		// Invert due to the camera display being flipped
forward.x = -forward.x;
up.x = -up.x;

	// DirectX y-coordinates are upside-down so we flip them:
if (get_is_directx_pipeline()){
	right.y = -right.y;
	forward.y = -forward.y;
	up.y = -up.y;
}

draw_line_width_color(cx, cy, cx + forward.x, cy + forward.y, 3, c_red, c_red);
draw_line_width_color(cx, cy, cx + right.x, cy + right.y, 3, c_blue, c_blue);
draw_line_width_color(cx, cy, cx + up.x, cy + up.y, 3, c_lime, c_lime);

// Render 'fade out' for bone scroll menu:
if (instance_exists(obj_bone_scroll)){
	draw_set_alpha(0.6);
	draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(), c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1.0)
}

// Render error messages:
if (array_length(error_array) > 0){
	var cx = display_get_gui_width() * 0.5 - 398 * 0.5;
	var cy = display_get_gui_height() * 0.5;
	var text = (array_length(error_array) > 1 ? "Errors:\n  " : "Error:\n  ");
	text += string_join_ext("\n  ", error_array);
	
	var c = make_color_rgb(24 + 32, 24 + 32, 48 + 64);
	var text_h = string_height_ext(text, -1, 386);
	cy -= text_h * 0.5 - 12;
	
	var a = 1.0;
	var t = min(3000 * array_length(error_array), 12000);
	if (current_time - error_time > t)
		a = max(0, 1.0 - ((current_time - t) - error_time) * 0.001);
		
	draw_set_alpha(a);
	
	draw_rectangle_color(cx, cy, cx + 24 + 386, cy + max(text_h + 24, 48), c, c, c, c, false);
	draw_rectangle_color(cx, cy, cx + 24 + 386, cy + max(text_h + 24, 48), c_white, c_white, c_white, c_white, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_ext(cx + 6 + 386 * 0.5, cy + max(text_h + 24, 48) * 0.5, text, -1, 386);
	
	if (a <= 0)
		error_array = [];
	
	draw_set_alpha(1.0);
}