/// ABOUT
/// An exceptionally basic material that allows you to specify a custom shader
/// to execute as part of the render pipeline. The custom shader is expected
///	to render out to the necessary GBuffer surfaces and the shader will be
/// automatically provided with uniforms from the rendering system if they
/// exist in the shader.

/// @stub	Needs full implementing!
function MaterialShader(shader) : Material() constructor {
	#region PROPERTIES
	self.shader = shader;
	#endregion
	
	#region METHODS
	
	function apply(){
/// @stub implement
	}
	
	function get_shader(){
		return shader;
	}
	#endregion
	
	#region INIT
	if (not shader_is_compiled(shader))
		Exception.throw_conditional(string_ext("shader [{0}] is not compiled!", [shader_get_name(shader)]));
	
/// @stub	Add rendering uniform checks for the shader and record the ones that exist in the shader
///			so that they are provided upon apply.
	#endregion
}