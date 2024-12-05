/// @about
/// A generic data container that can be added into a partition system. Usually
/// used as a wraper for a Body or some other complex structure. The data contains
/// A center position and extends to specify a volume. Not all partitioning systems
/// will use volume-based calculations and may only regard the position.

/// Partition data shapes can be simpler as we just need a base shape that is quick
/// to process.
enum PARTITION_DATA_SHAPE {
	ray,
	aabb,
	infinite	// Special-case shapes that can't really be bound into a partitioning system easily
}

function PartitionData(data) constructor {
	#region PROPERTIES
	static INDEX_COUNTER = 0;
	
	self.index = INDEX_COUNTER++;
	data_shape = PARTITION_DATA_SHAPE.aabb;
	self.data = data;
	self.aabb = aabb();
	self.ray = undefined;	// If a ray, this is set to an orientation
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
				self.data_shape = PARTITION_DATA_SHAPE.aabb;
			}
			else {
				data.get_collidable().transform(data);
				var position = vec_add_vec(data.get_data("collision.offset", vec()), data.position);
				var extends = data.get_data(["collision", "extends"], vec());
				self.aabb.position = position;
				self.aabb.extends = extends;
				
				if (is_instanceof(data.get_collidable(), Ray)){
					self.data_shape = PARTITION_DATA_SHAPE.ray;
					if (not data.get_data("collision.static", false))
						self.ray = data.get_data(["collision", "orientation"], vec(1, 0, 0));
					else
						self.ray = data.get_collidable().orientation;
				}
				else if (is_instanceof(data.get_collidable(), Plane)){
/// @stub	Think of a better way for these to be implemented 
					self.data_shape = PARTITION_DATA_SHAPE.infinite; // Bit of a work-around for now
					self.ray = undefined;
				}
				else{
					self.data_shape = PARTITION_DATA_SHAPE.aabb;
					self.ray = undefined;
				}
			}
		}
		else if (is_vec(data)){
			self.aabb.position = vec_duplicate(data);
			self.aabb.extends = vec();
			self.data_shape = PARTITION_DATA_SHAPE.aabb;
		}

		if (not is_undefined(parent)){
			var partition = parent.partition;
			partition.update_data(self);
		}
	}
	
	function _detach_signals(){
		data.signaler.remove_signal("set_position", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_rotation", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_scale", new Callable(self, calculate_properties));
		data.signaler.remove_signal("set_collidable", new Callable(self, calculate_properties));
		data.signaler.remove_signal("collision_data_updated", new Callable(self, calculate_properties));
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
		data.signaler.add_signal("collision_data_updated", new Callable(self, calculate_properties));
		data.signaler.add_signal("free", new Callable(self, _detach_signals));
	}
	calculate_properties();
	#endregion
}