/// @about
/// A simple linear fog that fades to a color (or alpha) based on camera clip ranges.
/// @param	{real}	znear		near-clipping distance to start the fog
/// @param	{real}	zfar		far-clipping distance where the fog is fully opaque
/// @param	{color}	color		color of the fog (unless using alpha-only)
/// @param	{real}	alpha		alpha component of the fog to blend towards
/// @param	{bool}	alpha_only	if true, color is not blended, just alpha (useful w/ skyboxes)
function PPFXFog(znear=0.75, zfar=0.9, color=c_black, alpha=1.0, alpha_only=false) : PostProcessFX(shd_fog_linear) constructor {
	#region METHODS
	function set_range(znear, zfar){
		uniforms.u_vRange.value = [znear, zfar];
	}
	
	function set_color(color, alpha, alpha_only=false){
		uniforms.u_vColor.value = [color_get_red(color) / 255, color_get_green(color) / 255, color_get_blue(color) / 255, alpha];
		uniforms.u_iAlphaOnly.value = alpha_only;
	}
	#endregion
	
	#region INIT
	self.set_custom_uniforms({
		"u_vRange" : {
			value : [znear, zfar],
			set_func : shader_set_uniform_f
		},
		"u_vColor" : {
			value : [color_get_red(color) / 255, color_get_green(color) / 255, color_get_blue(color) / 255, alpha],
			set_func : shader_set_uniform_f
		},
		"u_iAlphaOnly" : {
			value : alpha_only,
			set_func : shader_set_uniform_i
		}
	});
	#endregion
}