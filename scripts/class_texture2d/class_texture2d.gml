/// @about
/// A special texture container that can be used with Materials to specify 
/// textures in more detail.

function Texture2D(texture_id, is_sRGB=false)  : U3DObject() constructor {
	#region PROPERTIES
	self.texture = texture_id;
	self.is_sRGB = is_sRGB;
	texel_width = texture_get_texel_width(texture);
	texel_height = texture_get_texel_height(texture);
	texture_uvs = texture_get_uvs(texture);
	#endregion
	
	#region METHODS
	function get_texture(){
		return texture;
	}
	
	/// @desc	Returns if the texture is in the sRGB color space.
	function get_is_srgb(){
		return is_sRGB;
	}
	
	/// @desc	Returns if the texture is on its own texture page. This is usually
	///			desired for 3D models.
	function get_is_separate_page(){
		if (texture_get_width(texture) < 1.0)
			return false;
		
		if (texture_get_height(texture) < 1.0)
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
		var uvs = texture_get_uvs(texture);
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
	#endregion
}