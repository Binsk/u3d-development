/// @about
///	A sphere collision must be of equal size in all directions. If the parent
///	body is scaled, the smallest scale axis will be used as the scale factor
/// for the entire sphere.

function Sphere(radius) : AABB(vec(radius, radius, radius)) constructor {
	#region STATIC METHODS
	static collide_sphere = function(sphere_a, sphere_b, node_a, node_b){
		var position_a = vec_add_vec(node_a.position, node_a.get_data(["collision", "offset"], vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data(["collision", "offset"], vec()));
		var extends_a = node_a.get_data(["collision", "aabb_extends"], sphere_a.extends);
		var extends_b = node_b.get_data(["collision", "aabb_extends"], sphere_b.extends);
		var radius_a = vec_min_component(extends_a);
		var radius_b = vec_min_component(extends_b);
		
		var distance = vec_magnitude(vec_sub_vec(position_a, position_b));
		if (distance > radius_a + radius_b)	// No collision
			return undefined;
		
		var radius_combined = radius_a + radius_b;
		var push_vector = vec_normalize(vec_sub_vec(position_a, position_b));
		push_vector = vec_mul_scalar(push_vector, (radius_a + radius_b) - distance);
		var data = new CollidableDataSpatial(node_a, node_b, Sphere, Sphere);
		data.data.push_vector = push_vector;
		data.data.push_forward = vec((radius_combined - abs(position_a.x - position_b.x)) * sign(position_a.x - position_b.x), 0, 0);
		data.data.push_up = vec((radius_combined - abs(position_a.y - position_b.y)) * sign(position_a.y - position_b.y), 0, 0);
		data.data.push_right = vec((radius_combined - abs(position_a.z - position_b.z)) * sign(position_a.z - position_b.z), 0, 0);
		return data;
	}

	static collide_aabb = function(sphere_a, aabb_b, node_a, node_b){
		var position_a = vec_add_vec(node_a.position, node_a.get_data(["collision", "offset"], vec()));
		var position_b = vec_add_vec(node_b.position, node_b.get_data(["collision", "offset"], vec()));
		var extends_a = node_a.get_data(["collision", "aabb_extends"], sphere_a.extends);
		var extends_b = node_b.get_data(["collision", "aabb_extends"], aabb_b.extends);
		var radius_a = vec_min_component(extends_a);
		
		var point_edge = aabb_clamp_vec(aabb(position_b, extends_b), position_a);
		var is_collision = false;
		var is_inside = false;
		if (vec_equals_vec(point_edge, position_a)){ // Center of sphere fell inside the bounding box
			is_collision = true;
			is_inside = true;
		}
		else // See if close enough for intersection
			is_collision = (vec_magnitude(vec_sub_vec(point_edge, position_a)) <= radius_a);
		
		if (not is_collision) // No collision; we're done
			return undefined;
		
		var push_vector;
		var data = new CollidableDataSpatial(node_a, node_b, Sphere, AABB);
		data.data.push_forward = vec((radius_a - abs(point_edge.x - position_b.x)) * sign(point_edge.x - position_b.x), 0, 0);
		data.data.push_up = vec(0, (radius_a - abs(point_edge.y - position_b.y)) * sign(point_edge.y - position_b.y), 0);
		data.data.push_right = vec(0, 0, (radius_a - abs(point_edge.z - position_b.z)) * sign(point_edge.z - position_b.z));
		
		if (is_inside) // If fully inside; just find the smallest axis-aligned push vector 
			push_vector = vec_min_magnitude(data.data.push_forward, data.data.push_up, data.data.push_right);
		else{ // If not fully inside, push out from the closest point
			push_vector = vec_sub_vec(position_a, point_edge);
			push_vector = vec_mul_scalar(vec_normalize(push_vector), radius_a - vec_magnitude(push_vector));
		}
		
		data.data.push_vector = push_vector;
		return data;
	}
	#endregion

	#region METHODS
	function render_debug(node){
		super.execute("render_debug", [node]);
		var r_color = [color_get_red(draw_get_color()) / 255, color_get_green(draw_get_color()) / 255, color_get_blue(draw_get_color()) / 255];
		transform(node);
		
		var render_extends = node.get_data(["collision", "aabb_extends"], self.extends);
		var radius = vec_min_component(render_extends);
		var vformat = VertexFormat.get_format_instance([VERTEX_DATA.position]).get_format();
		var vbuffer = vertex_create_buffer();
		
		vertex_begin(vbuffer, vformat);
		
		var d = (2 * pi) / 32;
		for (var i = 0 ; i < 32; ++i){
			var t1 = d * i;
			var t2 = d * (i + 1);
			var ct1 = cos(t1) * radius;
			var ct2 = cos(t2) * radius;
			var st1 = sin(t1) * radius;
			var st2 = sin(t2) * radius;
			
			vertex_position_3d(vbuffer, ct1, 0, -st1);
			vertex_position_3d(vbuffer, ct2, 0, -st2);
			
			vertex_position_3d(vbuffer, 0, ct1, -st1);
			vertex_position_3d(vbuffer, 0, ct2, -st2);
			
			vertex_position_3d(vbuffer, ct1, -st1, 0);
			vertex_position_3d(vbuffer, ct2, -st2, 0);
		}
		
		vertex_end(vbuffer);
		
		uniform_set("u_vColor", shader_set_uniform_f, r_color);
		var matrix_model = matrix_get(matrix_world);
		
		matrix_set(matrix_world, matrix_build_translation(vec_add_vec(node.position, node.get_data(["collision", "offset"], vec()))));
		vertex_submit(vbuffer, pr_linelist, -1);
		matrix_set(matrix_world, matrix_model);
		
		vertex_delete_buffer(vbuffer);
	}
	#endregion

	#region INIT
	#endregion
}