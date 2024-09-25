/// @about
/// A body represents a 3D thing in the scene. It can contain a mesh, collision
/// shape, and handle various interactions and signals.

function Body() : Node() constructor {
	#region PROPERTIES
	model_instance = undefined;			// Renderable 3D model
	collision_instance = undefined;		// Collision shape
	collision_bits = 0;					// Collision layer bits we occupy
	collision_scan_bits = 0;			// Collision layer bits we scan for collisions
	#endregion
	
	#region METHODS
	function set_model(model){
		if (not is_instanceof(model, Model)){
			Exception.throw_conditional("invalid type, expected [Model]!");
			return;
		}
		
		model_instance = model;
	}
	#endregion
	
	#region INIT
	#endregion
}