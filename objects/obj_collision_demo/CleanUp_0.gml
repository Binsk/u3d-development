for (var i = array_length(body_array) - 1; i >= 0; --i){
	body_array[i].free();
	delete body_array[i];
}

body_array = [];

camera.free();
delete camera;

body_floor.free();
delete body_floor;

plane_body.free();
delete plane_body;

gltf_box.free();
delete gltf_box;

instance_destroy(obj_u3d_controller);