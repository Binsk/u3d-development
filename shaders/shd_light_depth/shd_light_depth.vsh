/// @about
/// Renders a simplified version of the gbuffer shader specifically for a light and is
/// intended for generating a directional shadow map.
attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV
attribute vec3 in_TextureCoord1;	// Tangent
attribute vec4 in_TextureCoord2;    // Bone IDs
attribute vec4 in_TextureCoord3;    // Bone weights

const int c_iMaxBones = 80;     // Note: Count is doubled if scaling is disabled
const int c_iBoneInfluence = 4; // Number of bones that can influence a vertex

uniform mat4 u_mBone[c_iMaxBones];  // Matrix transforms for each bone
uniform int u_iBoneNoScale;         // Whether or not bones have scaling; modifies how data is read

varying vec2 v_vTexcoord;

mat4 build_matrix(vec4 vQuaternion, vec3 vTranslation){
    mat4 mMatrix = mat4(vec4(1, 0, 0, 0), vec4(0, 1, 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
    // Set position:
    mMatrix[3][0] = vTranslation.x;
    mMatrix[3][1] = vTranslation.y;
    mMatrix[3][2] = vTranslation.z;
    
    // Rotation:
    mMatrix[0][0] = 1.0 - 2.0 * (vQuaternion.y * vQuaternion.y + vQuaternion.z * vQuaternion.z);
    mMatrix[0][1] = 2.0 * (vQuaternion.x * vQuaternion.y + vQuaternion.z * vQuaternion.w);
    mMatrix[0][2] = 2.0 * (vQuaternion.x * vQuaternion.z - vQuaternion.y * vQuaternion.w);
    
    mMatrix[1][0] = 2.0 * (vQuaternion.x * vQuaternion.y - vQuaternion.z * vQuaternion.w);
    mMatrix[1][1] = 1.0 - 2.0 * (vQuaternion.x * vQuaternion.x + vQuaternion.z * vQuaternion.z);
    mMatrix[1][2] = 2.0 * (vQuaternion.y * vQuaternion.z + vQuaternion.x * vQuaternion.w);
    
    mMatrix[2][0] = 2.0 * (vQuaternion.x * vQuaternion.z + vQuaternion.y * vQuaternion.w);
    mMatrix[2][1] = 2.0 * (vQuaternion.y * vQuaternion.z - vQuaternion.x * vQuaternion.w);
    mMatrix[2][2] = 1.0 - 2.0 * (vQuaternion.x * vQuaternion.x + vQuaternion.y * vQuaternion.y);    
    
    return mMatrix;
}

void main()
{
    vec4 vPosition = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    
    // Calculate bone transforms:
    vec4 vPositionFinal = vec4(0.0);
    ivec4 ivBoneID = ivec4(in_TextureCoord2);
    vec4 vBoneWeight = in_TextureCoord3; // Weights should add to 1!

        // Morph for each bone
    int iLoopCount = 0;
    int iMaxBones = c_iMaxBones;
    if (u_iBoneNoScale > 0)
        iMaxBones *= 2;
        
    for (int i = 0; i < c_iBoneInfluence; ++i){
        if (ivBoneID[i] < 0)
            continue;
        
        if (ivBoneID[i] >= iMaxBones){
            vPositionFinal = vPosition;
            break;
        }
        
        iLoopCount += 1;
        
        mat4 mMatrix;
        if (u_iBoneNoScale == 0) // Regular matrix morph
            mMatrix = u_mBone[ivBoneID[i]];
        else{ // Quat + translation pair
            int iIndex = int(float(ivBoneID[i]) * 0.5);
            int iOffset = int(ceil(fract(float(ivBoneID[i]) * 0.5))) * 2;
            mMatrix = u_mBone[iIndex];
            mMatrix = build_matrix(mMatrix[iOffset], mMatrix[iOffset + 1].xyz);
        }
        
        vec4 vPositionLocal = mMatrix * vPosition;
        vPositionFinal += vPositionLocal * vBoneWeight[i];
    }

        // Normalize results:
    float fDivisor = dot(vBoneWeight, vec4(1, 1, 1, 1));
    if (iLoopCount > 0 && abs(fDivisor) > 0.0001) // Only apply if we actually had bones sent over
        vPosition = vPositionFinal / fDivisor;
    
    vPosition = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    gl_Position = vPosition;

    v_vTexcoord = in_TextureCoord0;
    
    #ifdef _YY_HLSL11_
    /// Note:   Each attribute must be referenced under Windows, otherwise we
    ///         get data sent to the wrong attribute and it breaks things like
    ///         skeletal animation. These throwaway assignments work around
    ///         the issue.
    vec3 vFoo = in_TextureCoord1;
	vec4 vBar = in_Colour;
	vec3 vFooBar = in_Normal;
	#endif
}
