/// @about
/// The default shader used by spatial materials to build the GBuffer. This shader
/// writes out all the necessary GBuffer textures and calculates skeletal animation.
precision highp float;
#define OPT_SKELETAL

attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV
attribute vec3 in_TextureCoord1;	// Tangent

#ifdef OPT_SKELETAL
attribute vec4 in_TextureCoord2;    // Bone IDs
attribute vec4 in_TextureCoord3;    // Bone weights
const int c_iMaxBones = 80;
const int c_iBoneInfluence = 4; // Number of bones that can influence a vertex
uniform mat4 u_mBone[c_iMaxBones];  // Matrix transforms for each bone
uniform int u_iBoneNoScale;         // Whether or not bones have scaling; modifies how data is read
#endif

varying vec2 v_vTexcoord;
varying vec4 v_vColor;
varying mat3 v_mRotation;

#ifdef OPT_SKELETAL
/// @desc	Builds a matrix out of a rotational quaternion and translation vector.
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
#endif

void main()
{
    vec4 vPosition = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    vec3 vNormal = in_Normal;
    vec3 vTangent = in_TextureCoord1;
    
	#ifdef OPT_SKELETAL
    // Calculate bone transforms:
/// @stub   Figure out how to get skeletal animation working in web browser.
///         mMatrix = u_mBone[ivBoneID[i]]; seems to be the issue due to the array access
    vec4 vPositionFinal = vec4(0.0);
    vec3 vNormalFinal = vec3(0.0);
    vec3 vTangentFinal = vec3(0.0);
    ivec4 ivBoneID = ivec4(in_TextureCoord2);
    vec4 vBoneWeight = in_TextureCoord3; // Weights should add to 1!
    int iMaxBones = c_iMaxBones;
    if (u_iBoneNoScale > 0)
        iMaxBones *= 2;

        // Morph for each bone
    int iLoopCount = 0;
    for (int i = 0; i < c_iBoneInfluence; ++i){
        if (ivBoneID[i] < 0)
            continue;
        
        if (ivBoneID[i] >= iMaxBones){
            vPositionFinal = vPosition;
            vNormalFinal = vNormal;
            break;
        }
        
        iLoopCount += 1;
        mat4 mMatrix;
        if (u_iBoneNoScale == 0) // Regular matrix morph
            mMatrix = u_mBone[ivBoneID[i]];
        #ifndef _YY_GLSLES_
        else{ // Quat + translation pair
            int iIndex = int(float(ivBoneID[i]) * 0.5);
            int iOffset = int(ceil(fract(float(ivBoneID[i]) * 0.5))) * 2;
            mMatrix = u_mBone[iIndex];
            mMatrix = build_matrix(mMatrix[iOffset], mMatrix[iOffset + 1].xyz);
        }
        #else
        else{ // Quat + translation pair
            int iIndex = int(float(ivBoneID[i]) * 0.5);
            int iOffset = int(ceil(fract(float(ivBoneID[i]) * 0.5))) * 2;
            mMatrix = u_mBone[iIndex];
            
            vec4 vV1;
            vec4 vV2;
            if (iOffset < 2){
                vV1 = mMatrix[0];
                vV2 = mMatrix[1];
            }
            else {
                vV1 = mMatrix[2];
                vV2 = mMatrix[3];
            }
            mMatrix = build_matrix(vV1, vV2.xyz);
        }
        #endif
        
        vec4 vPositionLocal = mMatrix * vPosition;
        vPositionFinal += vPositionLocal * vBoneWeight[i];
        
        mat3 mBone = mat3(mMatrix);
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
    #endif
	
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    vNormal = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * vNormal);
    vTangent = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * vTangent);
    vec3 vBiTangent = normalize(cross(vNormal, vTangent));
    
    v_mRotation = mat3(vTangent, vBiTangent, vNormal);
    v_vColor = in_Colour;
    v_vTexcoord = in_TextureCoord0;
}
