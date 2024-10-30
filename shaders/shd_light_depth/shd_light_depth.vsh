attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV
attribute vec3 in_TextureCoord1;	// Tangent
attribute vec4 in_TextureCoord2;    // Bone IDs
attribute vec4 in_TextureCoord3;    // Bone weights

const int c_iMaxBones = 96;
const int c_iBoneInfluence = 4; // Number of bones that can influence a vertex

uniform mat4 u_mBone[c_iMaxBones];  // Matrix transforms for each bone

varying vec2 v_vTexcoord;

void main()
{
    vec4 vPosition = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    
    // Calculate bone transforms:
    vec4 vPositionFinal = vec4(0.0);
    ivec4 ivBoneID = ivec4(in_TextureCoord2);
    vec4 vBoneWeight = in_TextureCoord3; // Weights should add to 1!

        // Morph for each bone
    int iLoopCount = 0;
    for (int i = 0; i < c_iBoneInfluence; ++i){
        if (ivBoneID[i] < 0)
            continue;
        
        if (ivBoneID[i] >= c_iMaxBones){
            vPositionFinal = vPosition;
            break;
        }
        
        iLoopCount += 1;
        
        vec4 vPositionLocal = u_mBone[ivBoneID[i]] * vPosition;
        vPositionFinal += vPositionLocal * vBoneWeight[i];
    }

        // Normalize results:
    float fDivisor = dot(vBoneWeight, vec4(1, 1, 1, 1));
    if (iLoopCount > 0 && abs(fDivisor) > 0.0001) // Only apply if we actually had bones sent over
        vPosition = vPositionFinal / fDivisor;
    
    vPosition = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    gl_Position = vPosition;

    v_vTexcoord = in_TextureCoord0;
}
