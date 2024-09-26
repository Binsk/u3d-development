/// @about
/// A point light that has a limited reach based on its radius.

function LightPoint(position=vec(), radius=1) : Light() constructor {
	#region PROPERTIES
	uniform_sampler_albedo = -1;
	uniform_sampler_normal = -1;
	uniform_sampler_pbr = -1;
	#endregion
}