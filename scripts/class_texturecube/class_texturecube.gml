/// @about
/// A specially formated texture that is intended to be used as a cube map.
/// GameMaker does not provide access to built-in cube-mapping shader functions
/// nor mipmapping functions (required for PBR). This structure will build a 
/// special sprite to be used in-shader so these features can be added.
///
/// Cube map textures should be laid out in 4x3 ratio with the following faces:
///	[  ] [+Y] [  ] [  ]
///	[-Z] [+X] [+Z] [-X]
///	[  ] [-Y] [  ] [  ]
///
/// +X = forward
/// +Z = right
/// +Y = up
///	All faces should be oriented where +U is tangential 'up' and +V is tangential 'right'
///
///	That layout must be followed if TextureCube() is provided with a texture; otherwise
/// the class will auto-generate this layout via build() if textures are set through
/// 'set_face'
///
/// TextureCube resolution defines the max mip size. The resolution of a cube face can
///	be assumed to be `resolution * 0.25`

enum TEXTURECUBE_FACE {
	front,
	back,
	left,
	right,
	up,
	down
}

/// @desc	creates a new cube-map with the specified properties. Any texture supplied
///			is assumed to be in the correct format! Textures can also be manually built
///			through the TextureCube class to guarantee proper layout.
/// @param	{texture}	texture_id=undefined		pre-formatted cube-map texture to use
///	@param	{bool}		is_sRGB=false				whether or not the image is in sRGB spaceint}
/// @param	{int}		resolution=1024				resolution to use as maximum when generating mips
function TextureCube(texture_id=undefined, is_sRGB=false, resolution=1024) : Texture2D(texture_id, is_sRGB) constructor {
	#region PROPERTIES
	static BUILD_MAP = {};	// Used by the renderer to build all the textures before rendering
	
	build_data = {
		texture_id	// Finalized cube-map texture @ mip0
	};	// Used when auto-building a cube-map
	self.texture_id = undefined; // Finalized texture (including mips)
	self.sprite_index = undefined;	// Used to contain dynamic cube-map sprite
	mip_resolution = resolution;
	#endregion
	
	#region METHODS
	
	function set_texture(texture_id){
		// Wipe any old cube-maps:
		if (sprite_exists(sprite_index)){
			sprite_delete(sprite_index);
			sprite_index = undefined;
		}
		
		self.texture_id = undefined;
		
		struct_remove(build_data, "texture_id"); // Remove pre-defined texture
		build_data = {
			texture_id
		};
		TextureCube.BUILD_MAP[$ get_index()] = self;
	}
	
	/// @desc	Sets a texture to be used as a cube face. Setting a face will wipe
	///			the current cube data and re-build with the next render. Note that
	///			ALL 6 faces must be defined before building or a crash will occur.
	/// @param	{TEXTURECUBE_FACE}	face_index	the TEXTURECUBE_FACE to assign the texture to
	/// @param	{texture}			texture		GameMaker texture index to use for the cube map face
	function set_face(face_index, texture){
		face_index = clamp(real(face_index), 0, 5);
		// Wipe any old cube-maps:
		if (sprite_exists(sprite_index)){
			sprite_delete(sprite_index);
			sprite_index = undefined;
		}
		
		self.texture_id = undefined;
		
		struct_remove(build_data, "texture_id"); // Remove pre-defined texture
		build_data[$ face_index] = texture;
		TextureCube.BUILD_MAP[$ get_index()] = self;
	}
	
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
/// @stub	Implement!
			throw "NOT YET IMPLEMENTED";
		}
		else
			// texture_cube = build_data[$ "texture_id"];
			texture_cube = sprite_get_texture(spr_default_environment_cube, 1);
			
		// Now, with our texture, we must build the MIP levels:
		mip_surface = surface_create(mip_resolution * 1.5, mip_resolution * 0.75);
		var shader = shader_current();
		if (shader >= 0)
			shader_reset();
			
		var gpu_state = gpu_get_state();
		surface_set_target(mip_surface);
		draw_clear(c_black);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		gpu_set_tex_filter(true);
		gpu_set_cullmode(cull_noculling);
		// https://learnopengl.com/PBR/IBL/Specular-IBL
			// We generate 6 mips as we can fit it all in one column (minus the first image)
		for (var i = 0; i < 6; ++i){
			var mip_size_x = mip_resolution * power(0.5, i);
			var mip_size_y = mip_resolution * 0.75 * power(0.5, i);
			var mip_x = (i == 0 ? 0 : mip_resolution);
			var mip_y = (i == 0 ? 0 : mip_resolution * 0.75 - mip_size_y - mip_size_y);
			
			draw_primitive_begin_texture(pr_trianglestrip, texture_cube);
			draw_vertex_texture_color(mip_x, mip_y, 0, 0, c_white, 1.0);
			draw_vertex_texture_color(mip_x + mip_size_x, mip_y, 1, 0, c_white, 1.0);
			draw_vertex_texture_color(mip_x, mip_y + mip_size_y, 0, 1, c_white, 1.0);
			draw_vertex_texture_color(mip_x + mip_size_x, mip_y + mip_size_y, 1, 1, c_white, 1.0);
			draw_primitive_end();
		}
		
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
	
	super.mark("free");
	function free(){
		if (sprite_exists(self.sprite_index)){
			sprite_delete(self.sprite_index);
			self.texture_id = undefined;
		}
		build_data = {};
		struct_remove(TextureCube.BUILD_MAP, get_index());
		super.execute("free");
	}
	#endregion
}