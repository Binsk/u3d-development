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
instance_destroy(obj_u3d_controller); // Destroy all U3D controller systems
