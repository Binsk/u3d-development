/// @about
/// There are a few systems that need some initialization to make global access
/// possible right at game start. This script handles doing this in a static
/// order to prevent any conflicts.
#region DEFINE NECESSARY STATICS
var foo = new Exception();
delete foo;
#endregion

U3D = {
	RENDERING : {
		MATERIAL : {
			missing_texture : new MaterialSpatial()
		}
	}
}

U3D.RENDERING.MATERIAL.missing_texture.set_texture("albedo", sprite_get_texture(spr_missing_texture, 0));