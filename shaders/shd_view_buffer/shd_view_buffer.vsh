/// @about
///	A number of shaders require the fragment view vector and it is somewhat slow to calculate.
/// This shader calculates it into a buffer that can be passed into those shaders to reduce
/// the number of matrix OPs in the fragment shader.

attribute vec3 in_Position;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;

    v_vTexcoord = in_TextureCoord;
}
