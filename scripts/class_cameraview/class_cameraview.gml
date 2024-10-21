/// @about
/// A CameraView is a camera with 1 eye that renders a scene and automatically 
/// displays it onto the screen. This is the most commonly used camera. Buffer size
/// will be auto-calculated based on obj_render_controller's render mode and the anchor
/// will specify where on the screen it will render.

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
	uniform_tonemap = -1;
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
		
		buffer_width = anchor.get_dx(rwidth);
		buffer_height = anchor.get_dy(rheight);
	}
	
	function render(body_array, light_array){
		render_eye(eye_id, body_array, light_array);
	}
	
	function render_out(){
		if (render_stages <= 0)
			return;
		
		if (uniform_sampler_texture < 0)
			uniform_sampler_texture = shader_get_sampler_index(shd_tonemap, "u_sTexture");
		
		if (uniform_tonemap < 0)
			uniform_tonemap = shader_get_uniform(shd_tonemap, "u_iTonemap");
		
		var rw = render_width;
		var rh = render_height;
		
		gpu_set_blendmode(bm_normal);
		shader_set(shd_tonemap);
		texture_set_stage(uniform_sampler_texture, gbuffer.textures[$ CAMERA_GBUFFER.final]);
		shader_set_uniform_i(uniform_tonemap, render_tonemap);
		draw_primitive_begin_texture(pr_trianglestrip, -1);
		draw_vertex_texture(anchor.get_x(rw), anchor.get_y(rh), 1, 0);
		draw_vertex_texture(anchor.get_x(rw) + anchor.get_dx(rw), anchor.get_y(rh), 0, 0);
		draw_vertex_texture(anchor.get_x(rw), anchor.get_y(rh) + anchor.get_dx(rh), 1, 1);
		draw_vertex_texture(anchor.get_x(rw) + anchor.get_dx(rw), anchor.get_y(rh) + anchor.get_dy(rh), 0, 1);
		draw_primitive_end();
		shader_reset();
	}
	#endregion
	
	#region INIT
	// Register the eye so it is cleaned up along with this instance:
	add_child_ref(eye_id.set_unique_hash());
	#endregion
}