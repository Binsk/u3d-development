/// @about
/// Performs gamma correction on the input texture. This shader is generally used
/// as a separate PPFX pass if some effects need a manually handled gamma correction.
attribute vec3 in_Position;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;
void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vTexcoord = in_TextureCoord;
}
