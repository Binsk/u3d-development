/// @about
/// The default shader used by spatial materials to build the GBuffer. This shader
/// writes out all the necessary GBuffer textures and calculates skeletal animation.
attribute vec3 in_Position;         // Vertex position
attribute vec3 in_Normal;           // Vertex normal
attribute vec4 in_Colour;           // Vertex color
attribute vec2 in_TextureCoord0;    // Texture UV
attribute vec3 in_TextureCoord1;	// Tangent
attribute vec4 in_TextureCoord2;    // Bone IDs
attribute vec4 in_TextureCoord3;    // Bone weights

const int c_iMaxBones = 80;
const int c_iBoneInfluence = 4; // Number of bones that can influence a vertex

uniform vec4 u_vAlbedoUV;
uniform vec4 u_vNormalUV;
uniform vec4 u_vPBRUV;
uniform vec4 u_vEmissiveUV;
uniform mat4 u_mBone[c_iMaxBones];  // Matrix transforms for each bone
uniform int u_iBoneNoScale;         // Whether or not bones have scaling; modifies how data is read

varying vec2 v_vTexcoordAlbedo;
varying vec2 v_vTexcoordNormal;
varying vec2 v_vTexcoordPBR;
varying vec2 v_vTexcoordEmissive;
varying vec4 v_vColor;
varying vec4 v_vPosition;
varying mat3 v_mRotation;

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
        else{ // Quat + translation pair
            int iIndex = int(float(ivBoneID[i]) * 0.5);
            int iOffset = int(ceil(fract(float(ivBoneID[i]) * 0.5))) * 2;
            mMatrix = u_mBone[iIndex];
            mMatrix = build_matrix(mMatrix[iOffset], mMatrix[iOffset + 1].xyz);
        }
        
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
    
    v_vPosition = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vPosition;
    gl_Position = v_vPosition;
    vNormal = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * vNormal);
    vTangent = normalize(mat3(gm_Matrices[MATRIX_WORLD]) * vTangent);
    vec3 vBiTangent = normalize(cross(vNormal, vTangent));
    
    v_mRotation = mat3(vTangent, vBiTangent, vNormal);
    v_vColor = in_Colour;
/// @todo	Remove these custom texcoord aspects; they aren't working correctly and aren't likely
///			to be needed in the end after all due to how glTF loading is being handled.
    v_vTexcoordAlbedo = mix(u_vAlbedoUV.xy, u_vAlbedoUV.zw, in_TextureCoord0);
    v_vTexcoordNormal = mix(u_vNormalUV.xy, u_vNormalUV.zw, in_TextureCoord0);
    v_vTexcoordPBR = mix(u_vPBRUV.xy, u_vPBRUV.zw, in_TextureCoord0);
    v_vTexcoordEmissive = mix(u_vEmissiveUV.xy, u_vEmissiveUV.zw, in_TextureCoord0);
}
