/// @about
/// A Ray defines a 3D infinite line that is defined with a starting point and 
/// orientation.

/// @param	{vec}	orientation			the orientation of the ray
function Ray(orientation=vec(1, 0, 0)) : Collidable() constructor {
	#region PROPERTIES
	self.orientation = vec_normalize(orientation);
	#endregion
	
	#region STATIC METHODS
	/// @desc	Returns collision data between two rays.
	/// @param	{Ray}	ray_a
	/// @param	{Ray}	ray_b
	/// @param	{Node}	node_a		node defining spatial information for ray_a
	/// @param	{Node}	node_b		node defining spatial information for ray_b
	static collide_ray = function(ray_a, ray_b, node_a, node_b){
/// @stub	implement 
		return undefined;
	}
	
	/// @desc	Returns collision data bteween a ray and a plane.
	/// @param	{Ray}	ray
	/// @param	{Plane}	plane
	/// @param	{Node}	node_a		node defining spatial information for ray
	/// @param	{Node}	node_b		node defining spatial information for plane
	static collide_plane = function(ray_a, plane_b, node_a, node_b){
		var plane_normal = node_b.get_data(["collision", "orientation"], plane_b.normal);
		var ray_normal = node_a.get_data(["collision", "orientation"], ray_a.orientation);
		var ray_position = vec_add_vec(node_a.position, node_a.get_data("collision.offset", vec()));
		var plane_position = vec_add_vec(node_b.position, node_b.get_data("collision.offset", vec()));
		
		var dot_direction = vec_dot(ray_normal, plane_normal);
		var dot_location = -vec_dot(plane_normal, vec_sub_vec(ray_position, plane_position));
		
		if (abs(dot_direction) <= 0.001) // Close to perpendicular
			return undefined;
		
		var is_back = false;
		if (dot_direction > 0) // Determine back-faced collision
			is_back = true;
		
		var d = dot_location / dot_direction;
		if (d < 0) // Pointing away from the plane
			return undefined;
		
		var dx = vec_mul_scalar(ray_normal, d); // Offset from ray start the collision occurs
		var data = new CollidableData(Ray, Plane);
		
		data.data = {
			is_backface : is_back,	// Whether or not the ray is intersecting the backside of the plane
			intersection_point : vec_add_vec(ray_position, dx)	// Intersection point in world space
		};
		return data;
	}

	/// @desc	Returns collision data between a ray and an AABB.
	static collide_aabb = function(ray_a, aabb_b, node_a, node_b){
		var ray_position = vec_add_vec(node_a.position, node_a.get_data("collision.offset", vec()));
		var aabb_position = vec_add_vec(node_b.position, node_b.get_data("collision.offset", vec()));

		var ray_position_adjusted = vec_sub_vec(ray_position, aabb_position); // Position relative to the aabb
		var aabb_extends = node_b.get_data(["collision", "extends"], aabb_b.extends); // Get transformed extends
		
		// Check if the ray falls INSIDE the box; if so, the origin point is the point of intersection
		/// @note We don't calculate the EDGE position of the ray as if the box is hollow.
		if (abs(ray_position_adjusted.x) <= aabb_extends.x and
			abs(ray_position_adjusted.y) <= aabb_extends.y and
			abs(ray_position_adjusted.z) <= aabb_extends.z){
			var data = new CollidableData(Ray, AABB);
			data.data = {
				is_inside : true,
				intersection_point : ray_position
			};
			
			return data;
		}
		
		// Failed inside check so we calculate proper collision point:
		var ray_orientation;
		if (node_a.get_data("collision.static", false))
			ray_orientation = ray_a.orientation;
		else
			ray_orientation = node_a.get_data(["collision", "orientation"], ray_a.orientation);
			
		var ray_inv_orientation = vec_invert(ray_orientation);
		var ray_sign = vec_sign(ray_inv_orientation);
		
		ray_inv_orientation.x = (ray_inv_orientation.x >= infinity ? 10000000 : ray_inv_orientation.x); // Convert 'infinity' since (infinity * 0 == NaN in GM)
		ray_inv_orientation.y = (ray_inv_orientation.y >= infinity ? 10000000 : ray_inv_orientation.y);
		ray_inv_orientation.z = (ray_inv_orientation.z >= infinity ? 10000000 : ray_inv_orientation.z);

		// Compare x / y axes first:
		var tmin = (aabb_extends.x * -ray_sign.x - ray_position_adjusted.x) * ray_inv_orientation.x;
		var tmax = (aabb_extends.x * ray_sign.x - ray_position_adjusted.x) * ray_inv_orientation.x;
		var tymin = (aabb_extends.y * -ray_sign.y - ray_position_adjusted.y) * ray_inv_orientation.y;
		var tymax = (aabb_extends.y * ray_sign.y - ray_position_adjusted.y) * ray_inv_orientation.y;
		
		if (tmin >= infinity or tymin >= infinity)
			return undefined;
		
		if (tmin > tymax or tymin > tmax)
			return undefined;
		
		// Potential collision; pick the best one:
		if (tymin > tmin)
			tmin = tymin;
		
		if (tymax < tmax)
			tmax = tymax;
		
		// Compare result against z axis:
		var tzmin = (aabb_extends.z * -ray_sign.z - ray_position_adjusted.z) * ray_inv_orientation.z;
		var tzmax = (aabb_extends.z * ray_sign.z - ray_position_adjusted.z) * ray_inv_orientation.z;

		if (tzmin >= infinity)
			return undefined;
		
		if (tmin > tzmax or tzmin > tmax)
			return undefined;
			
		if (tzmin > tmin)
			tmin = tzmin;

		var data = new CollidableData(Ray, AABB);
		data.data = {
			is_inside : false,
			intersection_point : vec_add_vec(ray_position, vec_set_length(ray_orientation, tmin))
		};
		
		return data;
	}
	#endregion
	
	#region METHODS
	super.register("transform");
	function transform(node){
		if (not super.execute("transform", [node]))
			return false;

		if (node.get_data("collision.static", false))
			node.set_data(["collision", "orientation"], vec_normalize(self.orientation));
		else 
			node.set_data(["collision", "orientation"], vec_normalize(matrix_multiply_vec(node.get_model_matrix(), self.orientation)));
		
		return true;
	}
	
	super.register("render_debug");
	function render_debug(node){
		super.execute("render_debug", [node]);
		var r_color = [color_get_red(draw_get_color()) / 255, color_get_green(draw_get_color()) / 255, color_get_blue(draw_get_color()) / 255];
		transform(node);
		var length = Eye.ACTIVE_INSTANCE.zfar;
		var rotation = node.get_data(["collision", "orientation"], vec(1, 0, 0)); 
		
		var vformat = VertexFormat.get_format_instance([VERTEX_DATA.position]).get_format();
		var vbuffer = vertex_create_buffer();
		vertex_begin(vbuffer, vformat);
		vertex_position_3d(vbuffer, 0, 0, 0);
		vertex_position_3d(vbuffer, rotation.x * length, rotation.y * length, rotation.z * length);
		vertex_end(vbuffer);
		
		uniform_set("u_vColor", shader_set_uniform_f, r_color);
		var matrix_model = matrix_get(matrix_world);
		matrix_set(matrix_world, matrix_build_translation(vec_add_vec(node.position, node.get_data(["collision", "offset"], vec()))));
		vertex_submit(vbuffer, pr_linelist, -1);
		vertex_delete_buffer(vbuffer);
	}
	#endregion
}