/// @about
///	The Collidable class is a base template class that defines a 3D interactible
/// shape. Collidables do not have position, rotation, or scale values as they are
/// just shape definitions. The collision system can be given a node to represent
/// a transform to a collidable when detecting collisions; this allows re-use of
///	collidable shapes over multiplie bodies.

function Collidable() : U3DObject() constructor {
	#region PROPERTIES
	#endregion
	
	#region STATIC METHODS
	/// @desc	Calculates if there is a collision between two collidables and, if so,
	///			returns a CollidableData structure. 'undefined' is returned if no 
	///			collision exists. If no collision handler exists, no collision will be
	///			returned.
	///	@note	If transform() has not been called on each collidable before-hand then
	///			it must be done manually.
	/// @param	{Collidable}	collidable_a	the first collidable shape to use
	/// @param	{Collidable}	collidable_b	the second collidable shape to use
	/// @param	{Node}			node_a			the first node to use for transforms
	/// @param	{Node}			node_b			the second node to use for transforms
	static calculate_collision = function(collidable_a, collidable_b, node_a, node_b) {
		#region RAY CHECKS
		if (is_instanceof(collidable_a, Ray)){
			if (is_instanceof(collidable_b, Ray))
				return Ray.collide_ray(collidable_a, collidable_b, node_a, node_b);
			if (is_instanceof(collidable_b, Plane))
				return Ray.collide_plane(collidable_a, collidable_b, node_a, node_b);
		}
		#endregion
			
		return undefined;
	}
	#endregion
	
	#region METHODS
	/// @desc	Given a node, calculates the transformed values relative to the 
	///			collidable. The results should be stored in the node's 'generic data'
	///			container for cache before a collision is checked.
	function transform(node){}
	#endregion
	
	#region INIT
	#endregion
}