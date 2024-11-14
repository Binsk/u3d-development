/// @about
/// A CameraView is a camera with 1 eye that renders a scene and automatically 
/// displays it onto the screen. This is the most commonly used camera. Buffer size
/// will be auto-calculated based on obj_render_controller's render mode and the anchor
/// will specify where on the screen it will render.

/// @param	{real}	znear		the closest to the camera a model can render
/// @param	{real}	zfar		the furthest from the camera a model can render
/// @param	{fov}	fov			the field of view of the camera
/// @param	{Anchor2D} anchor	the anchor used to specify where in the window the camera should render
function CameraView(znear=0.01, zfar=1024, fov=45, anchor=new Anchor2D()) : Camera() constructor {
	#region PROPERTIES
	self.anchor = anchor;
	supersample_multiplier = 1.0;
	render_width = 1;	// Size of the canvas we render out on (not our actual render size)
	render_height = 1;
	render_tonemap = CAMERA_TONEMAP.simple;
	eye_id = new Eye(self, znear, zfar, fov);
	
	#region SHADER UNIFORMS
	uniform_sampler_texture = -1;
	#endregion
	
	#endregion
	
	#region METHODS
	/// @desc	How much to multiply the size of the render buffer by.
	function set_supersample_multiplier(multiplier=1.0){
		supersample_multiplier = max(0.01, multiplier);
	}
	
	function get_eye_array(){
		return [eye_id];
	}
	
	function update_render_size(){
		var rwidth = 1;
		var rheight = 1;
		with (obj_render_controller){
			if (render_mode == RENDER_MODE.draw){
				if (not surface_exists(application_surface))
					return;
					
				rwidth = surface_get_width(application_surface);
				rheight = surface_get_height(application_surface);
			}
			else {
				rwidth = display_get_gui_width();
				rheight = display_get_gui_height();
			}
		}
		
		render_width = rwidth;
		render_height = rheight;
		
		rwidth = ceil(supersample_multiplier * rwidth);
		rheight = ceil(supersample_multiplier * rheight);
		
		var ndx = anchor.get_dx(rwidth);
		var ndy = anchor.get_dy(rheight);
		if ((buffer_width ?? 1 != ndx) or (buffer_height ?? 1) != ndy){
			eye_id.matrix_projection = undefined;
			eye_id.matrix_inv_projection = undefined;
		}
		
		buffer_width = ndx;
		buffer_height = ndy;
	}
	
	function render(body_array, light_array){
		render_eye(eye_id, body_array, light_array);
	}
	
	function render_out(){
		if (render_stages <= 0)
			return;
		
		if (uniform_sampler_texture < 0)
			uniform_sampler_texture = shader_get_sampler_index(shd_tonemap, "u_sTexture");
		
		var rw = render_width;
		var rh = render_height;
		
		gpu_set_blendmode(bm_normal);
		shader_set(shd_tonemap);
		texture_set_stage(uniform_sampler_texture, gbuffer.textures[$ CAMERA_GBUFFER.final]);
		uniform_set("u_iTonemap", shader_set_uniform_i, render_tonemap);
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(anchor.get_x(rw), anchor.get_y(rh), 1, 0);
		draw_vertex_texture(anchor.get_x(rw) + anchor.get_dx(rw), anchor.get_y(rh), 0, 0);
		draw_vertex_texture(anchor.get_x(rw), anchor.get_y(rh) + anchor.get_dx(rh), 1, 1);
		draw_vertex_texture(anchor.get_x(rw) + anchor.get_dx(rw), anchor.get_y(rh) + anchor.get_dy(rh), 0, 1);
		draw_primitive_end(); 
		shader_reset();
	}
	
	/// @desc	Given 2D point on the canvas, projects the location into 3D space and
	///			updates the provided ray to contain projection direction. Origin point
	///			can be assumed to be the camera's position.
	/// @param	{real}	px	relative x-coordinate on the camera's canvas w/o supersample modifications
	/// @param	{real}	py	relative y-coordinate on the camera's canvas w/o supersample modifications
	/// @param	{Ray}	ray	collidable ray to update w/ the mouse projection
	function calculate_world_ray(px, py, ray){
		if (not is_instanceof(ray, Ray)){
			Exception.throw_conditional("invalid type, expected [Ray]!");
			return;
		}
		
		px *= supersample_multiplier;
		py *= supersample_multiplier;
		
		if (px < 0 or py < 0)
			return;
		if (px >= render_width or py >= render_height)
			return;
			
		// Convert to screen space [-1..1]:
			/// @note	We inverte the axes due to the rendering canvas being flipped
		px = -((px / render_width) * 2.0 - 1.0);
		py = -((1.0 - py / render_height) * 2.0 - 1.0);
		if (get_is_directx_pipeline())
			py = -py;
		
		// Reverse-project the point into view space:
		var point_far = matrix_transform_vertex(eye_id.get_inverse_projection_matrix(), px, py, 1, 1);	// Location at far-clip
		var point_near = matrix_transform_vertex(eye_id.get_inverse_projection_matrix(), px, py, 0, 1);	// Location at near-clip
		
		for (var i = 0; i < 3; ++i){ // Scale by w
			point_far[i] /= point_far[3];
			point_near[i] /= point_near[3];
		}
		
		// Project from view space into world space:
		point_far = matrix_transform_vertex(eye_id.get_inverse_view_matrix(), point_far[0], point_far[1], point_far[2], 1);
		point_near = matrix_transform_vertex(eye_id.get_inverse_view_matrix(), point_near[0], point_near[1], point_near[2], 1);
		
		ray.orientation = vec_normalize(vec(point_far[0] - point_near[0], point_far[1] - point_near[1], point_far[2] - point_near[2]));
	}
	#endregion
	
	#region INIT
	// Register the eye so it is cleaned up along with this instance:
	add_child_ref(eye_id.set_unique_hash());
	#endregion
}