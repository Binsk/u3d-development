/// @about
/// A generic data container that can be added into a partition system. Usually
/// used as a wraper for a Body or some other complex structure. The data contains
/// A center position and extends to specify a volume. Not all partitioning systems
/// will use volume-based calculations and may only regard the position.

function PartitionData(data) constructor {
	#region PROPERTIES
	static INDEX_COUNTER = 0;
	
	self.index = INDEX_COUNTER++;
	self.data = data;
	self.aabb = aabb();
	self.parent = undefined;	// The partition node we are inside of 
	#endregion
	
	#region METHODS
	/// @desc	Manually sets the position in 3D space; this will override any
	///			auto-calculated values.
	function set_position(position=vec()){
		self.aabb.position = position;
	}
	
	/// @desc	Manually sets the extends in 3D space; this will override any
	///			auto-calculated values.
	function set_extends(extends=vec()){
		self.aabb.extends = extends;
	}
	
	function set_parent(node){
		if (not is_instanceof(node, PartitionNode)){
			Exception.throw_conditional("invalid type, expected [PartitionNode]!");
			return;
		}
		
		if (not is_undefined(parent))
			parent.remove_data(self);
		
		parent = node;
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
			if (is_undefined(data.get_collidable())){
				self.aabb.position = vec_duplicate(data.position);
				self.aabb.extends = vec();
			}
			else {
				data.get_collidable().transform(data);
				var position = vec_add_vec(data.get_data("collision.offset", vec()), data.position);
				var extends = data.get_data(["collision", "extends"], vec());
				self.aabb.position = position;
				self.aabb.extends = extends;
			}
		}
		else if (is_vec(data)){
			self.aabb.position = vec_duplicate(data);
			self.aabb.extends = vec();
		}

		if (not is_undefined(parent)){
			var partition = parent.partition;
/// @stub	Slow; a temporary measure until proper adjusting is added
			partition.remove_data(self);
			partition.add_data(self)
		}
	}
	
	function _detach_signals(){
		data.signaler.remove_signal("set_position", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_rotation", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_scale", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_collidable", new Callable(self, calculate_properties));
		data.signaler.remove_signal("free", new Callable(self, _detach_signals));
/// @stub	Make this update the partitioning system so it gets removed from the node it's in
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