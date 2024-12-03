// Lower alpha:
var array = model.get_material_array();
for (var i = array_length(array) - 1; i >= 0; --i){
	 var material = array[i];
	 material.render_stage = CAMERA_RENDER_STAGE.translucent;
	 material.set_albedo_factor(material.get_albedo_color_factor(), material_alpha);
}

material_alpha -= frame_delta * 0.1;

// Move box up and spin:
body.set_position(vec_mul_scalar(Node.AXIS_UP, frame_delta * 0.1), true);
body.set_rotation(veca_to_quat(veca(0, 1, 0, degtorad(180 * frame_delta * 0.1))), true);

if (material_alpha <= 0)
	instance_destroy();