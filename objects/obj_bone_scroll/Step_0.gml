y_velocity += (mouse_wheel_up() - mouse_wheel_down()) * 512;
y_velocity = clamp(y_velocity, -2048, 2048);