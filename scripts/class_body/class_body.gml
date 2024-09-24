/// @about
/// A body represents a 3D thing in the scene. It can contain a mesh, collision
/// shape, and handle various interactions and signals.

function Body() : Node() constructor {
	#region PROPERTIES
	mesh_instance = undefined;			// Renderable 3D mesh
	collision_instance = undefined;		// Collision shape
	collision_bits = 0;					// Collision layer bits we occupy
	collision_scan_bits = 0;			// Collision layer bits we scan for collisions
	#endregion
	
	#region METHODS
	#endregion
	
	#region INIT
	#endregion
}