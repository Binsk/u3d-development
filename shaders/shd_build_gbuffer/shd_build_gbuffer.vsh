attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV
attribute vec3 in_TextureCoord1;	// Tangent

uniform vec4 u_vAlbedoUV;
uniform vec4 u_vNormalUV;
uniform vec4 u_vPBRUV;
uniform vec4 u_vEmissiveUV;

varying vec2 v_vTexcoordAlbedo;
varying vec2 v_vTexcoordNormal;
varying vec2 v_vTexcoordPBR;
varying vec2 v_vTexcoordEmissive;
varying vec4 v_vColor;
varying vec4 v_vPosition;
varying mat3 v_mRotation;

void main()
{
    vec4 vPosition = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    v_vPosition = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    
    gl_Position = v_vPosition;
    vec3 vNormal = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * in_Normal);
    vec3 vTangent = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * in_TextureCoord1);
    vec3 vBiTangent = normalize(cross(vNormal, vTangent));
    
    #ifdef _YY_HLSL11_
        vTangent = -vTangent;
        vNormal = -vNormal;
        vBiTangent = -vBiTangent;
	#endif
    
    v_mRotation = mat3(vTangent, vBiTangent, vNormal);
    v_vColor = in_Colour;
    v_vTexcoordAlbedo = mix(u_vAlbedoUV.xy, u_vAlbedoUV.zw, in_TextureCoord0);
    v_vTexcoordNormal = mix(u_vNormalUV.xy, u_vNormalUV.zw, in_TextureCoord0);
    v_vTexcoordPBR = mix(u_vPBRUV.xy, u_vPBRUV.zw, in_TextureCoord0);
    v_vTexcoordEmissive = mix(u_vEmissiveUV.xy, u_vEmissiveUV.zw, in_TextureCoord0);
}
