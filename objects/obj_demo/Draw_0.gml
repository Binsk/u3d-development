gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
gpu_set_cullmode(cull_noculling);
matrix_set(matrix_view, matrix_build_lookat(cos(current_time / 2000) * 10, 5, sin(current_time / 2000) * 10, 0, 0, 0, 0, 1, 0));
matrix_set(matrix_projection, matrix_build_projection_perspective_fov(-50, -room_width / room_height, 0.01, 1024));
vertex_submit(vbuffer, pr_trianglestrip, -1);
vertex_submit(box.vbuffer, pr_trianglelist, -1);