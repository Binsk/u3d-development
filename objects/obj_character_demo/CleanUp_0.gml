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

instance_destroy(obj_character)
instance_destroy(obj_sphere);