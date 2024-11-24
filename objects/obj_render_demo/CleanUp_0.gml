camera.free();
delete camera;

light_ambient.free();
delete light_ambient;
light_directional.free();
delete light_directional;

environment_map.free();
delete environment_map;

instance_destroy(obj_u3d_controller); // Destroy all U3D controller systems
