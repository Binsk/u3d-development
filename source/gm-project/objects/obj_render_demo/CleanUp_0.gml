camera.free();
delete camera;

light_ambient.free();
delete light_ambient;
light_directional.free();
delete light_directional;

environment_map.free();
delete environment_map;

if (not is_undefined(body_floor)){
	body_floor.free();
	delete body_floor;
}
