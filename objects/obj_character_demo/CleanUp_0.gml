camera.free();
delete camera;

body_floor.free();
delete body_floor;

light_ambient.free();
delete light_ambient;

for (var i = 0; i < array_length(light_array); ++i){
	light_array[i].free();
	delete light_array[i];
}

scene_body.free();
delete scene_body;