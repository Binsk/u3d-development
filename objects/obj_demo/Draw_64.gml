var material_count = 0;
var primitive_count = 0;
var mesh_count = 0;
var model_count = 0;
var triangle_count = 0;
var animation_string = "Animation Tracks:\n";

with (obj_button){
	if (is_undefined(body))
		continue;
	
	material_count += model.get_material_count();
	primitive_count += model.get_primitive_count();
	mesh_count += model.get_mesh_count();
	triangle_count += model.get_triangle_count();
	model_count++;
	
	animation_string += "  " + text + ": ";
	if (array_length(animation_names) <= 0)
		animation_string += "N/A";
	else
		animation_string += string_join_ext(", ", animation_names);
}

if (not is_undefined(body) and obj_render_controller.has_body(body)){
	material_count += body.model_instance.get_material_count();
	primitive_count += body.model_instance.get_primitive_count();
	mesh_count += body.model_instance.get_mesh_count();
	triangle_count += body.model_instance.get_triangle_count();
	model_count++;
}

draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_text_color(12, 12, $"{gpu_string}\n" + 
						$"\nFPS: {fps}\nResolution: {camera.buffer_width}x{camera.buffer_height}" + 
						$"\nGBuffer vRAM: {string(camera.get_vram_usage() / 1024 / 1024)}MB" + 
						$"\n\nMaterials: {material_count}\nModels: {model_count}\nMeshes: {mesh_count}\nPrimitives: {primitive_count}\nTriangles: {triangle_count}",
						c_white, c_white, c_white, c_white, 1.0);

draw_text_color(12 + 256, 12, animation_string, c_white, c_white, c_white, c_white, 1.0);