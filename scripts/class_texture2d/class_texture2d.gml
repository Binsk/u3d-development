/// @about
/// A special texture container that can be used with Materials to specify 
/// textures in more detail.

function Texture2D(texture_id=undefined) : U3DObject() constructor {
	#region PROPERTIES
	self.texture_id = texture_id;
	texel_width = 0;
	texel_height = 0;
	texture_uvs = [0, 0, 0, 0];
	
	is_mipmapping = false;
	mipmap_mode = tf_point;
	#endregion
	
	#region STATIC METHODS
	/// @desc	A convenient function that returns a GameMaker texture to represent
	///			a "missing texture". This material is defined in `scr_u3d_init`.
	static get_missing_texture = function(){
		return U3D.RENDERING.MATERIAL.missing.texture.albedo.texture.get_texture();
	}
	#endregion
	
	#region METHODS
	/// @desc	Sets the GameMaker texture to use when rendering.
	function set_texture(texture_id){
		self.texture_id = texture_id;
		if (not is_undefined(texture_id))
			cache_properties();
	}
	
	/// @desc	Assigns whether this texture should have mipmapping or not and, if so,
	///			the filtering mode to use.
	function set_mipmapping(enabled, mode=tf_point){
		is_mipmapping = enabled;
		mipmap_mode = mode;
	}
	
		/// @desc	Returns the GameMaker texture stored by this texture.
	function get_texture(){
		if (is_undefined(self.texture_id))
			return Texture2D.get_missing_texture();
			
		return self.texture_id;
	}
	
	/// @desc	Returns if the texture is on its own texture page. This is usually
	///			desired for 3D models.
	function get_is_separate_page(){
		if (texture_get_width(texture_id) < 1.0)
			return false;
		
		if (texture_get_height(texture_id) < 1.0)
			return false;
		
		return true
	}
	
	/// @desc	Returns if the texture belongs to a sprite. If not, it is likely
	///			a surface.
	function get_is_sprite_texture(){
		return array_length(texture_uvs) > 4;
	}
	
	/// @desc	Given a u-coordinate for a 3D mesh, assuming [0..1], returns the
	///			relative u coordinate for this texture.
	function get_u(u){
		var uvs = texture_get_uvs(texture_id);
		return lerp(texture_uvs[0], texture_uvs[2], u);
	}
	
	/// @desc	Given a v-coordinate for a 3D mesh, assuming [0..1], returns thes
	///			relative v coordinate for this texture.
	function get_v(v){
		return lerp(texture_uvs[1], texture_uvs[3], v);
	}
	
	/// @desc	Return the texel width for the texture
	function get_txw(){
		return texel_width;
	}
	
	/// @desc	Return the texel height for the texture
	function get_txh(){
		return texel_height;
	}
	
	/// @desc	Applies the mipmap settings of the texture to the specified sampler id.
	function apply_mip(sampler_id){
		gpu_set_tex_mip_enable_ext(sampler_id, is_mipmapping ? mip_on : mip_off);
		gpu_set_tex_filter_ext(sampler_id, is_mipmapping);
	}
	
	/// @desc	Sets the texture to the specified sampler; similar to sampler_set(), but
	///			this also applies the texture settings.
	function set(name){
		static UNIFORM_CACHE = {};
		if (is_undefined(texture_id))
			return false;
		
		var shader = shader_current();
		if (shader < 0) // Skip if no shader set
			return false;
		
		var data = (UNIFORM_CACHE[$ name] ?? {});
		var uniform = data[$ shader];
		
		if (is_undefined(uniform)){ // If we haven't checked this uniform + shader combo, look it up
			uniform = shader_get_sampler_index(shader, name);
			data[$ shader] = uniform;
			UNIFORM_CACHE[$ name] = data;
		}
		
		if (uniform >= 0){ // Uniform exists in the shader; set it
			apply_mip(uniform);
			texture_set_stage(uniform, texture_id);
			return true;
		}
		
		return false;
	}
	
	function cache_properties(){
		texel_width = texture_get_texel_width(texture_id);
		texel_height = texture_get_texel_height(texture_id);
		texture_uvs = texture_get_uvs(texture_id);
	}
	#endregion
	
	#region INIT
	if (not is_undefined(texture_id))
		cache_properties();
	#endregion
}