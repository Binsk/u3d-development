/// This is a very simple character that just moves in their facing direction
/// and follows the mouse.

#region PROPERTIES
movement_speed = 0;
movement_acceleration = 1.0;
movement_friction = 2.0;
maximum_speed = 10.0;
gravity_strength = 0.25;
jump_strength = 6.0;
vertical_speed = 0;
target_vector = vec();	// Vector we are trying to move to
#endregion

#region METHODS
#endregion

#region INIT
var gltf = new GLTFBuilder("demo-sophia.glb");
model = gltf.generate_model();
animation = gltf.generate_animation_tree();
animation.generate_unique_hash();
model.generate_unique_hash();
body = new Body();
body.set_model(model);
body.set_animation(animation);

animation.add_animation_layer_auto(0, "Idle");
animation.start_animation_layer(0);

obj_render_controller.add_body(body);
obj_animation_controller.add_body(body);

gltf.free();
delete gltf;
#endregion