/// @about
/// A generic material class that is fairly worthless on its own, however it is
/// a common base for all other material types.

function Material() : U3DObject() constructor {
	#region PROPERTIES
	render_keys = {};
	#endregion
	
	#region METHODS
	/// @desc	Should apply the necessary shaders, uniforms, and so-forth for
	///			the material. It will be automatically executed by the rendering
	///			system.
	/// @param	{RENDER_STAGE}	render_stage		the current rendering stage being executed
	function apply(render_stage){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Should return the appropriate shader to apply for this material.
	function get_shaders(){
		throw new Exception("cannot call virtual function!");
	}
	
	/// @desc	Some render situations might provide special data and this data
	///			will be provided through a structure of keys. Keys will be set
	///			before ANY other material processing and can be used at any stage
	///			of the rendering pipeline.
	function set_render_keys(keys={}){
		render_keys = keys;
	}
	#endregion
	
	#region INIT
	#endregion
}