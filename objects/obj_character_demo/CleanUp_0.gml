camera.free();
delete camera;

light_ambient.free();
delete light_ambient;

for (var i = 0; i < array_length(light_array); ++i){
	light_array[i].free();
	delete light_array[i];
}

scene0_body.free();
delete scene0_body;

dummy_body.free();
delete dummy_body;

for (var i = array_length(scene_body_array) - 1; i >= 0; --i){
	scene_body_array[i].free();
	delete scene_body_array[i];
}

body_motion_trigger.free();
delete body_motion_trigger;

instance_destroy(obj_character)
instance_destroy(obj_sphere);