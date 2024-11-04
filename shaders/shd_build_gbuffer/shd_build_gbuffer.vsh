attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV
attribute vec3 in_TextureCoord1;	// Tangent
attribute vec4 in_TextureCoord2;    // Bone IDs
attribute vec4 in_TextureCoord3;    // Bone weights

const int c_iMaxBones = 96;
const int c_iBoneInfluence = 4; // Number of bones that can influence a vertex

uniform vec4 u_vAlbedoUV;
uniform vec4 u_vNormalUV;
uniform vec4 u_vPBRUV;
uniform vec4 u_vEmissiveUV;
uniform mat4 u_mBone[c_iMaxBones];  // Matrix transforms for each bone

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
    vec3 vNormal = in_Normal;
    vec3 vTangent = in_TextureCoord1;
    
    // Calculate bone transforms:
    vec4 vPositionFinal = vec4(0.0);
    vec3 vNormalFinal = vec3(0.0);
    vec3 vTangentFinal = vec3(0.0);
    ivec4 ivBoneID = ivec4(in_TextureCoord2);
    vec4 vBoneWeight = in_TextureCoord3; // Weights should add to 1!

        // Morph for each bone
    int iLoopCount = 0;
    for (int i = 0; i < c_iBoneInfluence; ++i){
        if (ivBoneID[i] < 0)
            continue;
        
        if (ivBoneID[i] >= c_iMaxBones){
            vPositionFinal = vPosition;
            vNormalFinal = vNormal;
            break;
        }
        
        iLoopCount += 1;
        
        vec4 vPositionLocal = u_mBone[ivBoneID[i]] * vPosition;
        vPositionFinal += vPositionLocal * vBoneWeight[i];
        
        mat3 mBone = mat3(u_mBone[ivBoneID[i]]);
        vec3 vNormalLocal = mBone * vNormal;
        vNormalFinal += vNormalLocal * vBoneWeight[i];
        
        vec3 vTangentLocal = mBone * vTangent;
        vTangentFinal += vTangentLocal * vBoneWeight[i];
    }

        // Normalize results:
    float fDivisor = dot(vBoneWeight, vec4(1, 1, 1, 1));
    if (iLoopCount > 0 && abs(fDivisor) > 0.0001){ // Only apply if we actually had bones sent over
        vPosition = vPositionFinal / fDivisor;
        vNormal = normalize(vNormalFinal);
        vTangent = normalize(vTangentFinal);
    }
    
    v_vPosition = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    gl_Position = v_vPosition;
    vNormal = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * vNormal);
    vTangent = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * vTangent);
    vec3 vBiTangent = normalize(cross(vNormal, vTangent));
    
    v_mRotation = mat3(vTangent, vBiTangent, vNormal);
    v_vColor = in_Colour;
    v_vTexcoordAlbedo = mix(u_vAlbedoUV.xy, u_vAlbedoUV.zw, in_TextureCoord0);
    v_vTexcoordNormal = mix(u_vNormalUV.xy, u_vNormalUV.zw, in_TextureCoord0);
    v_vTexcoordPBR = mix(u_vPBRUV.xy, u_vPBRUV.zw, in_TextureCoord0);
    v_vTexcoordEmissive = mix(u_vEmissiveUV.xy, u_vEmissiveUV.zw, in_TextureCoord0);
}
