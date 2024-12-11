camera.free();
delete camera;

light_ambient.free();
delete light_ambient;

for (var i = 0; i < array_length(light_array); ++i){
	light_array[i].free();
	delete light_array[i];
}

for (var i = 0; i < array_length(collidable_bodies); ++i){
	collidable_bodies[i].free();
	delete collidable_bodies[i];
}

scene_body.free();
delete scene_body;

dummy_body.free();
delete dummy_body;

body_motion.free();
delete body_motion;

instance_destroy(obj_character)
instance_destroy(obj_sphere);