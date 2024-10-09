/// @about
/// A specially formated texture that is intended to be used as a cube map.
/// Note that GameMaker does NOT provide a means to use built-in GLSL/HLSL
/// cube mapping functions (or pass actual cube-maps) so this is faked through
/// regular sampler2D textures. This structure helps make sure the textures are
/// laid out correctly.
function TextureCube() : Texture2D() constructor {
	
}