event_inherited();
/// @stub	Implement proper bone update culling for animation tracks

/// @desc	Calculates the animation state updates for all bodies in the system.
function process(){ 
/// @stub	optimize forming the body array
	var instance_array = struct_get_values(body_map);
	for (var i = array_length(instance_array) - 1; i >= 0; --i){
		var animation = instance_array[i].get_animation();
		if (is_undefined(animation))
			continue;
		
		animation.process();
	}
}