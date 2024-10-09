attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV

uniform vec4 u_vAlbedoUV;
uniform vec4 u_vNormalUV;
uniform vec4 u_vPBRUV;

varying vec2 v_vTexcoordAlbedo;
varying vec2 v_vTexcoordNormal;
varying vec2 v_vTexcoordPBR;
varying vec4 v_vColor;
varying vec3 v_vNormal;
varying vec4 v_vPosition;

void main()
{
    vec4 vPosition = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    v_vPosition = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    gl_Position = v_vPosition;
    v_vNormal = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * in_Normal);
    
    v_vColor = in_Colour;
    v_vTexcoordAlbedo = mix(u_vAlbedoUV.xy, u_vAlbedoUV.zw, in_TextureCoord0);
    v_vTexcoordNormal = mix(u_vNormalUV.xy, u_vNormalUV.zw, in_TextureCoord0);
    v_vTexcoordPBR = mix(u_vPBRUV.xy, u_vPBRUV.zw, in_TextureCoord0);
}
