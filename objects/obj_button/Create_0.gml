signaler = new Signaler();
text = "";
text_tooltip = "";

width = 256;
height = 32;
gltf = undefined;
model = undefined;
body = undefined;
animation_tree = undefined;
is_hovered = false;
is_model_button = true;

function cleanup_model(){
	if (not is_model_button)
		return;
	
	if (not U3DObject.get_is_valid_object(body))
		return;
		
	obj_render_controller.remove_body(body);
	
	body.free();
	delete body;
	animation_tree = undefined;
	obj_demo.update_data_count();
}