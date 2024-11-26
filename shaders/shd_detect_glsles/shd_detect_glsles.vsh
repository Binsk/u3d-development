/// @about
/// A shader that is designed to fail to compile on GLSL ES. This allows forcing
/// detection for this specific shader language usage.
attribute vec3 in_Position;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    #ifdef _YY_GLSLES_
    foo = bar;
    #endif
}
