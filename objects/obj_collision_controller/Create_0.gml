event_inherited();
/// @about
/// The collision system handles signaling when collisions occur and recording
/// data about that collision. Collisions are processed in a passive manner,
/// meaning they should not be checked directly but instead handled through
/// signals.

/// @desc	Calculates the animation state updates for all bodies in the system.
function process(){
	/// @stub	optimize forming the body array
	var instance_array = struct_get_values(body_map);
	for (var i = array_length(instance_array) - 1; i >= 0; --i){
		
	}
}