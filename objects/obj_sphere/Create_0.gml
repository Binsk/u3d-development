#region PROPERTIES
body = undefined;
collidable = undefined;
model = undefined;
#endregion

#region METHODS
#endregion

#region INIT
body = new Body();
body.set_position(vec(x, 0.5, y));

var gltf = new GLTFBuilder("demo-sphere.glb");
model = gltf.generate_model();
model.generate_unique_hash();
model.freeze();

collidable = new Sphere(0.5);
collidable.generate_unique_hash();
collidable.set_static(body, true);

body.set_model(model);
body.set_collidable(collidable);

obj_render_controller.add_body(body);
obj_collision_controller.add_body(body);

gltf.free();
delete gltf;

#endregion