/// @desc	A (fake) mip-mapped TextureCube. Only really implemented to allow an irradiance
///			map sample for roughness sampling w/ environment maps. This class is jank as beans
/// 		and will need heavy adjustment.
/// @param	{texture}	texture_id	if set, uses this texture for the cube map
/// @param	{real}		resolution	resolution of the cube map to generate
/// @param	{real}		mip_count	number of mips to generate (0=single original texture)
/// @param	{bool}		is_pbr		if true, the mips will be blurred for use w/ pbr reflections
function TextureCubeMip(texture_id=undefined, resolution=1024, mip_count=0, is_pbr=false) : TextureCube(texture_id, resolution) constructor {
	#region INIT
	self.mip_count = clamp(mip_count, 1, 5);
	self.is_pbr = is_pbr;
	#endregion
	
	#region METHODS
	/// @desc	builds the necessary textures for this cube-map. This is executed automatically
	///			upon use, but it can also be called manually to prevent render hiccups at level
	///			start. Must be executed in a draw event due to the usage of surfaces.
	function build(){
		if (not is_undefined(texture_id)) // Already built; we can exit early
			return;
			
		if (event_type != ev_draw)
			throw new Exception(string_ext("cannot build TextureCube in event [{0}]!", [event_type]));
		
		// If no pre-defined texture, we must build it:
		var texture_surface = -1;
		var mip_surface = -1;
		var texture_cube = -1;
		if (is_undefined(build_data[$ "texture_id"])){
			// Check that we have all face defines:
			for (var i = 0; i < 6; ++i){
				if (is_undefined(build_data[$ i]))
					return Texture2D.get_missing_texture();
			}
			// Set texture_cube to the next texture
			texture_surface = surface_create(resolution, resolution);
			render_faces_to_cubemap(texture_surface);
			texture_cube = surface_get_texture(texture_surface);
		}
		else
			texture_cube = build_data[$ "texture_id"];
			
		// Now, with our texture, we must build the MIP levels:
		mip_surface = surface_create(resolution * 1.5, resolution * 0.75);
		var shader = shader_current();
		if (shader >= 0)
			shader_reset();
			
		var gpu_state = gpu_get_state();
		surface_set_target(mip_surface);
		draw_clear(c_black);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		gpu_set_tex_filter(true);
		gpu_set_cullmode(cull_noculling);
		
/// @stub	Implement PROPER conversion; this gaussian blur is a really hacky 'good enough for now' implementation
		// https://learnopengl.com/PBR/IBL/Specular-IBL
		// We generate mips as we can fit it all in one column (minus the first image)
		var surface_swap1 = surface_create(resolution, resolution);
		var surface_swap2 = surface_create(resolution, resolution);
			
		for (var i = 0; i <= mip_count; ++i){
			var mip_size_x = resolution * power(0.5, i);
			var mip_size_y = resolution * 0.75 * power(0.5, i);
			var mip_x = (i == 0 ? 0 : resolution);
			var mip_y = (i == 0 ? 0 : resolution * 0.75 - mip_size_y - mip_size_y);
			
			surface_set_target(surface_swap2);
			draw_primitive_begin_texture(pr_trianglestrip, texture_cube);
			draw_vertex_texture_color(0, 0, 0, 0, c_white, 1.0);
			draw_vertex_texture_color(resolution, 0, 1, 0, c_white, 1.0);
			draw_vertex_texture_color(0, resolution, 0, 1, c_white, 1.0);
			draw_vertex_texture_color(resolution, resolution, 1, 1, c_white, 1.0);
			draw_primitive_end();
			surface_reset_target();
			
			var surf1 = surface_swap2;
			var surf2 = surface_swap1;
			
			if (is_pbr){
				var iterations = (i == 0 ? 0 : min(16 * i, 64));
				shader_set(shd_gaussian_13);
				shader_set_uniform_f(shader_get_uniform(shd_gaussian_13, "u_vTexelSize"), 1 / 1024, 1 / 1024);
				
				for (var j = 0; j < iterations; ++j){
					var dx = cos(pi * 2 / iterations * j) * (iterations - j - 1);
					var dy = sin(pi * 2 / iterations * j) * (iterations - j - 1);
					surface_set_target(surf2);
					shader_set_uniform_f(shader_get_uniform(shd_gaussian_13, "u_vDirection"), dx, dy);
					draw_primitive_begin_texture(pr_trianglestrip, surface_get_texture(surf1));
					draw_vertex_texture_color(0, 0, 0, 0, c_white, 1.0);
					draw_vertex_texture_color(resolution, 0, 1, 0, c_white, 1.0);
					draw_vertex_texture_color(0, resolution, 0, 1, c_white, 1.0);
					draw_vertex_texture_color(resolution, resolution, 1, 1, c_white, 1.0);
					draw_primitive_end();
					surface_reset_target();
					surf1 = (j % 2 ? surface_swap1 : surface_swap2);
					surf2 = (j % 2 ? surface_swap2 : surface_swap1);
				}
				shader_reset();
			}
			
			draw_primitive_begin_texture(pr_trianglestrip, surface_get_texture(surf1));
			draw_vertex_texture_color(mip_x, mip_y, 0, 0, c_white, 1.0);
			draw_vertex_texture_color(mip_x + mip_size_x, mip_y, 1, 0, c_white, 1.0);
			draw_vertex_texture_color(mip_x, mip_y + mip_size_y, 0, 1, c_white, 1.0);
			draw_vertex_texture_color(mip_x + mip_size_x, mip_y + mip_size_y, 1, 1, c_white, 1.0);
			draw_primitive_end();
		}
		
		surface_free(surface_swap1);
		surface_free(surface_swap2);
		
		gpu_set_texfilter(false);
		gpu_set_blendmode(bm_normal);
		surface_reset_target();
		
		if (shader >= 0)
			shader_set(shader);
			
		gpu_set_state(gpu_state);
		
		self.sprite_index = sprite_create_from_surface(mip_surface, 0, 0, surface_get_width(mip_surface), surface_get_height(mip_surface), false, false, 0, 0);
		self.texture_id = sprite_get_texture(self.sprite_index, 0);
		
		// Clean up build-data
		if (surface_exists(texture_surface))
			surface_free(texture_surface);
		
		if (surface_exists(mip_surface))
			surface_free(mip_surface);
		
		build_data = {};
		cache_properties(); // Re-cache UVs and the like for quick look-ups
		struct_remove(TextureCube.BUILD_MAP, get_index());
	}
	#endregion
}