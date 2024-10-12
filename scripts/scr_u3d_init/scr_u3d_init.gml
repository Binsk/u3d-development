/// @about
/// There are a few systems that need some initialization to make global access
/// possible right at game start. This script handles doing this in a static
/// order to prevent any conflicts.
#region DEFINE NECESSARY STATICS
var foo = new Exception();
delete foo;

foo = new TextureCube();
delete foo;
#endregion

global.__u3d_global_data = {
	RENDERING : {
		MATERIAL : {
			missing_texture : new MaterialSpatial()
		}
	}
}

#macro U3D global.__u3d_global_data
// Delta time, in seconds, with safety values. Generally used for things like
// velocity.
#macro frame_delta clamp(delta_time / 1000000, 0.004, 0.067)
// Delta time, in percent, relative to a 60fps target. Generally used for lerp
// functions (like player rigidity, etc)
#macro frame_delta_relative clamp(60 / fps, 0.25, 4.0)

U3D.RENDERING.MATERIAL.missing_texture.set_texture("albedo", new Texture2D(sprite_get_texture(spr_missing_texture, 0)));