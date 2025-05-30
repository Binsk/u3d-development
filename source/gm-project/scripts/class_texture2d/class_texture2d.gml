/// @about
/// A special texture container that can be used with Materials to specify 
/// textures in more detail.

function Texture2D(texture_id=undefined) : U3DObject() constructor {
	#region PROPERTIES
	// Whether or not to convert Point / Linear filtering for generated textures.
	// This does NOT affect already-generated textures and is intended to be set
	// before model loading since glTF doesn't support an anisotropic filter setting.
	static ANISOTROPIC_OVERRIDE_POINT = false;
	static ANISOTROPIC_OVERRIDE_LINEAR = false;
	static ANISOTROPIC_OVERRIDE_MAX = undefined;
	self.texture_id = texture_id;
	texel_width = 0;
	texel_height = 0;
	texture_uvs = [0, 0, 0, 0];

	tex_mipmap_enabled = false;
	tex_filter = tf_point;
	tex_repeat = true;
	tex_anis_level = 16;
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
			self.cache_properties();
	}
	/// @desc	Sets whether the texture should render with mipmapping.
	function set_tex_mip_enable(enabled){
		tex_mipmap_enabled = bool(enabled);
	}
	
	/// @desc	Sets the texture filtering method for this texture. The setting may
	///			be overridden by ANISOTROPIC_OVERRIDE_* values.
	function set_tex_filter(filter=tf_point, ignore_override=false){
		if (not ignore_override){
			if (filter == tf_point and Texture2D.ANISOTROPIC_OVERRIDE_POINT)
				filter = tf_anisotropic;
			else if (filter == tf_linear and Texture2D.ANISOTROPIC_OVERRIDE_LINEAR)
				filter = tf_anisotropic;
		}
			
		tex_filter = filter;
	}
	
	/// @desc	Sets the anisotropic level to use when anisotropic filtering is enabled.
	///			The setting may be overridden by ANISOTROPIC_OVERRIDE_* values.
	function set_tex_anis_level(level=16, ignore_override=false){
		if (not ignore_override){
			if (not is_undefined(Texture2D.ANISOTROPIC_OVERRIDE_MAX))
				level = Texture2D.ANISOTROPIC_OVERRIDE_MAX;
		}
			
		tex_anis_level = clamp(level, 1, 16);
	}
	
	/// @desc	Sets whether or not sampling past the edge of this texture should wrap
	///			around to the other side or simply re-sample the closest texel.
	function set_tex_repeat(enabled){
		tex_repeat = bool(enabled);
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
	function apply_properties(sampler_id){
		var rep = tex_mipmap_enabled ? mip_on : mip_off;
		if (gpu_get_tex_mip_enable_ext(sampler_id) != rep)
			gpu_set_tex_mip_enable_ext(sampler_id, tex_mipmap_enabled ? mip_on : mip_off);
			
		if (rep){
			if (gpu_get_tex_mip_filter_ext(sampler_id) != tex_filter)
				gpu_set_tex_mip_filter_ext(sampler_id, tex_filter);
			
			if (tex_filter == tf_anisotropic){
				if (gpu_get_tex_max_aniso_ext(sampler_id) != tex_anis_level)
					gpu_set_tex_max_aniso_ext(sampler_id, tex_anis_level);
			}
		}
		else {
			if (gpu_get_tex_filter_ext(sampler_id) != tex_filter)
				gpu_set_tex_filter_ext(sampler_id, tex_filter);
		}

		if (gpu_get_tex_repeat_ext(sampler_id) != tex_repeat)
			gpu_set_tex_repeat_ext(sampler_id, tex_repeat);
	}
	
	/// @desc	Sends this texture to the specified sampler name. This will also
	///			apply texture settings, such as mipmapping, filtering, and repeat.
	function apply(name){
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
			self.apply_properties(uniform);
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
		self.cache_properties();
	#endregion
}