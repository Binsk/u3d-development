/// @about
/// A specially formated texture that is intended to be used as a cube map.
/// Note that GameMaker does NOT provide a means to use built-in GLSL/HLSL
/// cube mapping functions (or pass actual cube-maps) so this is faked through
/// regular sampler2D textures. This structure helps make sure the textures are
/// laid out correctly and it also handles faked mip-mapping for PBR roughness
/// blur.
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

/// @desc	creates a new cube-map with the specified properties. Any texture supplied
///			is assumed to be in the correct format! Textures can also be manually built
///			through the TextureCube class to guarantee proper layout.
/// @param	{texture}	texture_id=undefined		pre-formatted cube-map texture to use
///	@param	{bool}		is_sRGB=false				whether or not the image is in sRGB spaceint}
/// @param	{int}		resolution=1024				resolution to use as maximum when generating mips
function TextureCube(texture_id=undefined, is_sRGB=false, resolution=1024) : Texture2D(texture_id, is_sRGB) constructor {
	
	#region METHODS
	/// @desc	builds the necessary textures for this cube-map. This is executed automatically
	///			upon use, but it can also be called manually to prevent render hiccups at level
	///			start. Must be executed in a draw event due to the usage of surfaces.
	function build(){
		if (event_type != ev_draw)
			throw new Exception(string_ext("cannot build TextureCube in event [{0}]!", [event_type]));
	}
	#endregion
}