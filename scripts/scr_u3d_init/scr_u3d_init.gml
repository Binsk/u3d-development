/// @about
/// There are a few systems that need some initialization to make global access
/// possible right at game start. This script handles doing this in a static
/// order to prevent any conflicts.
#region DEFINE NECESSARY STATICS
var foo = new Exception();
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

U3D.RENDERING.MATERIAL.missing_texture.set_texture("albedo", new Texture2D(sprite_get_texture(spr_missing_texture, 0)));