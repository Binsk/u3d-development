/// @about
/// A button that loads a model and adds it to the render system when pressed.
///	Models are NOT cached so removing the model will require a fresh load.

event_inherited();
gltf = undefined;
model = undefined;
body = undefined;
animation_tree = undefined;
triangle_lerp = 0;	// Used to render part of the mesh as it 'loads in'
is_unloading = false;	// If true, plays 'unload' animation effect

slider_id = undefined;

function cleanup_model(){
	if (not U3DObject.get_is_valid_object(body))
		return;
		
	obj_render_controller.remove_body(body);
	
	body.free();
	delete body;
	
	animation_tree = undefined;
	obj_demo_controller.update_data_count();
	
	for (var i = 0; i < array_length(obj_demo_controller.model_scale_slider_array); ++i){
		var slider = obj_demo_controller.model_scale_slider_array[i];
		if (slider.button_id == id){
			array_delete(obj_demo_controller.model_scale_slider_array, i, 1);
			instance_destroy(slider);
			break;
		}
	}
}