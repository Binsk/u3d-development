/// @about
/// A generic data container that can be added into a partition system. Usually
/// used as a wraper for a Body or some other complex structure. The data contains
/// A center position and extends to specify a volume. Not all partitioning systems
/// will use volume-based calculations and may only regard the position.

function PartitionData(data) constructor {
	#region PROPERTIES
	static INDEX_COUNTER = 0;
	static TYPE_METHODS = {};
	
	self.index = INDEX_COUNTER++;
	self.data = data;
	self.position = vec();
	self.extends = vec();
	#endregion
	
	#region METHODS
	/// @desc	Manually sets the position in 3D space; this will override any
	///			auto-calculated values.
	function set_position(position=vec()){
		self.position = position;
	}
	
	/// @desc	Manually sets the extends in 3D space; this will override any
	///			auto-calculated values.
	function set_extends(extends=vec()){
		self.extends = extends;
	}
	
	function get_index(){
		return index;
	}
	
	function get_data(){
		return data;
	}
	
	function calculate_properties(){
		// Attempt to auto-calculate position and extends, based on the data
		if (is_instanceof(data, Body)){
			// If no collision instance, we have no size so just use position directly
			if (is_undefined(data.get_collidable()))
				self.position = vec_duplicate(data.position);
			else {
/// @stub	Account for collision shape, offset, scale, etc.
			}
		}
		else if (is_vec(data))
			self.position = vec_duplicate(data);

/// @stub Make this update the partitioning system so it can adjust for the new size / position
	}
	
	function _detach_signals(){
		data.signaler.remove_signal("set_position", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_rotation", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_scale", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_collidable", new Callable(self, calculate_properties));
		data.signaler.remove_signal("free", new Callable(self, _detach_signals));
/// @stub	Make this update the partitioning system so it gets removed
	}
	
	function toString(){
		return $"{index}";
	}
	#endregion
	
	#region INIT
	// If a body, connect signals so we auto-update properties every time the bdoy changes
	if (is_instanceof(data, Body)){
		data.signaler.add_signal("set_position", new Callable(self, calculate_properties));
		data.signaler.add_signal("set_rotation", new Callable(self, calculate_properties));
		data.signaler.add_signal("set_scale", new Callable(self, calculate_properties));
		data.signaler.add_signal("set_collidable", new Callable(self, calculate_properties));
		data.signaler.add_signal("free", new Callable(self, _detach_signals));
	}
	calculate_properties();
	#endregion
}