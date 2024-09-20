var cx = room_width * 0.5;
var cy = room_height * 0.5;
dir++;
vector = vec(dcos(dir), -dsin(dir));

var quat = vec_to_quat(vector);
var rotated_axis = quat_rotate_vec(quat, axis);
draw_circle_color(cx, cy, 8, c_red, c_red, false);
draw_circle_color(cx + rotated_axis.x, cy + rotated_axis.y, 24, c_white, c_white, false);