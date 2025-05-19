// Body array is freed by multimodel_box
body_array = [];

camera.free();
delete camera;

body_floor.free();
delete body_floor;

plane_body.free();
delete plane_body;

gltf_box.free();
delete gltf_box;

gltf_model.free();
delete gltf_model;

body_box.free();
delete body_box;

environment.free();
delete environment;

light_ambient.free();
delete light_ambient;

light_directional.free();
delete light_directional;

if (not is_undefined(collidable_box)){
	collidable_box.free();
	delete collidable_box;
}