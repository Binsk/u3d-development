/// @about
///	The Collidable class is a base template class that defines a 3D interactible
/// shape. Collidables do not have position, rotation, or scale values as they are
/// just shape definitions. The collision system can be given a node to represent
/// a transform to a collidable when detecting collisions; this allows re-use of
///	collidable shapes over multiplie bodies.
function Collidable() : U3DObject() constructor {
	#region STATIC METHODS
	/// @desc	Calculates if there is a collision between two collidables and, if so,
	///			returns a CollidableData structure. 'undefined' is returned if no 
	///			collision exists. If no collision handler exists, no collision will be
	///			returned.
	///	@note	If transform() has not been called on each collidable before-hand then
	///			it must be done manually. If added to the collision system then it will
	///			have been called automatically.
	/// @note	The collision order is not always collidable_a -> collidable_b. You can check
	///			the collision order through the returned CollidableData class.
	/// @param	{Collidable}	collidable_a	the first collidable shape to use
	/// @param	{Collidable}	collidable_b	the second collidable shape to use
	/// @param	{Node}			node_a			the first node to use for transforms
	/// @param	{Node}			node_b			the second node to use for transforms
	static calculate_collision = function(collidable_a, collidable_b, node_a, node_b) {
		#region RAY CHECKS
		if (is_instanceof(collidable_a, Ray)){
			if (is_instanceof(collidable_b, Ray))
				return undefined;	/// @stub	Implement!
			if (is_instanceof(collidable_b, Plane))
				return Ray.collide_plane(collidable_a, collidable_b, node_a, node_b);
			if (is_instanceof(collidable_b, AABB))
				return Ray.collide_aabb(collidable_a, collidable_b, node_a, node_b);
		}
		#endregion
		#region PLANE CHECKS
		if (is_instanceof(collidable_a, Plane)){
			if (is_instanceof(collidable_b, Ray))
				return Plane.collide_ray(collidable_a, collidable_b, node_a, node_b);
			if (is_instanceof(collidable_b, Plane))
				return undefined;	/// @stub	Implement!
			if (is_instanceof(collidable_b, AABB))
				return undefined;	/// @stub	Implement!
		}
		#endregion
		#region AABB CHECKS
		if (is_instanceof(collidable_a, AABB)){
			if (is_instanceof(collidable_b, Ray))
				return AABB.collide_ray(collidable_a, collidable_b, node_a, node_b);
			if (is_instanceof(collidable_b, Plane))
				return undefined;	/// @stub	Implement!
			if (is_instanceof(collidable_b, AABB))
				return AABB.collide_aabb(collidable_a, collidable_b, node_a, node_b);
		}
		#endregion
		#region SPHERE CHECKS
/// @stub	Implement!
		#endregion
		#region CAPSULE CHECKS
/// @stub	Implement!
		#endregion
		#region CONVEX HULL CHECKS
/// https://github.com/carolhmj/quickhull-3d/blob/main/Quickhull3D.js
/// @stub	Implement!
		#endregion
		
		return undefined;
	}
	#endregion
	
	#region METHODS
	/// @desc	Sets an offset relative to a node's origin. The offset only applies when
	///			this shape is compared alongside that node.
	/// @param	{Node}	node
	/// @param	{vec}	offset
	function set_offset(node, offset){
		if (not is_instanceof(node, Node)){
			Exception.throw_conditional("invalid type, expected [Node]!");
			return;
		}
		
		if (not is_vec(offset)){
			Exception.throw_conditional("invalid type, expected [vec]!");
			return;
		}
		
		node.clear_collision_data();
		node.set_data("collision.offset", offset);
	}
	
	/// @desc	Sets whether or not the collision shape should transform along with
	///			scale and rotations. If static then only translational movement will
	///			be updated. By default all shapes are dynamic.
	function set_static(node, is_static){
		node.clear_collision_data();
		node.set_data("collision.static", bool(is_static));
	}
	
	/// @desc	Given a node, calculates the transformed values relative to the 
	///			collidable. The results should be stored in the node's 'generic data'
	///			container for cache before a collision is checked.
	/// @param	{Node}	node
	function transform(node){
		if (node.has_collision_data())
			return false;
			
		var offset = node.get_data("collision.offset", undefined);
		if (is_undefined(offset))
			return true;
		
		if (node.get_data("collision.static", false))
			node.set_data("collision.offset", offset);
		else{
			offset = matrix_multiply_vec(node.get_model_matrix(), offset);	
			node.set_data("collision.offset", offset);
		}
		return true;
	}
	
	/// @desc	Renders a debug line mesh of the shape, if applicable. Mesh is
	///			generated on the fly and dynamic so it is slow to render.
	function render_debug(node){
		static COLORS = [
			c_red,		// No scan
			c_green,	// Scanned + miss
			c_yellow	// Scanned + hit
		]
		draw_set_color(COLORS[node.get_data("collision.debug_highlight", 0)]);
	}
	#endregion
}