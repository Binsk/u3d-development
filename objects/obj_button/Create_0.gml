/// @signals
/// pressed	()		-	Thrown when the button is pressed
event_inherited();

width = 256;
height = 32;
gltf = undefined;
model = undefined;
body = undefined;
animation_tree = undefined;
is_model_button = true;
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