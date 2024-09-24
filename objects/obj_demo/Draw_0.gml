camera.generate_gbuffer();
camera.set_position(vec(10 * cos(current_time / 2000), 10, 10 * sin(current_time / 2000)));
camera.look_at_up(vec());
gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
gpu_set_cullmode(cull_noculling);
matrix_set(matrix_view, camera.get_view_matrix());
matrix_set(matrix_projection, camera.get_projection_matrix());

material.apply(RENDER_STAGE.build_gbuffer);
// vertex_submit(vbuffer, pr_trianglestrip, -1);
vertex_submit(box.vbuffer, pr_trianglelist, sprite_get_texture(spr_default_white, 0));
shader_reset();
