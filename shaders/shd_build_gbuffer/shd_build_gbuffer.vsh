attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV

varying vec2 v_vTexcoord;
varying vec4 v_vColor;

void main()
{
    vec4 vPosition = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    
    v_vColor = in_Colour;
    v_vTexcoord = in_TextureCoord0;
}
