uniform sampler2D u_sAlbedo;
uniform sampler2D u_sNormal;
uniform sampler2D u_sPBR;

uniform vec3 u_vLightNormal;
uniform vec3 u_vLightColor;
uniform int u_iTranslucentPass; // Whether or not this is a translucent pass
varying vec2 v_vTexcoord;

#define vView vec3(0, 0, -1)
#define fPI 3.1415926535897932384626433

// https://learnopengl.com/PBR/Lighting
float distribution_ggx(vec3 vNormal, vec3 vHalf, float fRoughness){
    float fA = fRoughness * fRoughness;
    float fA2 = fA * fA;
    float fNdotH = max(dot(vNormal, vHalf), 0.0);
    float fNdotH2 = fNdotH * fNdotH;
    
    float fNumerator = fA2;
    float fDenominator = fNdotH2 * (fA2 - 1.0) + 1.0;
    fDenominator = fPI * fDenominator * fDenominator;
    
    return fNumerator / fDenominator;
}

float geometry_schlick_ggx(float fNdotV, float fRoughness){
    float fR = fRoughness + 1.0;
    float fK = (fR * fR) * 0.125;
    
    float fNumerator = fNdotV;
    float fDenominator = fNdotV * (1.0 - fK) + fK;
    
    return fNumerator / fDenominator;
}

float geometry_smith(vec3 vNormal, vec3 vLight, float fRoughness){
    float fNdotV = max(dot(vNormal, vView), 0.0);
    float fNdotL = max(dot(vNormal, vLight), 0.0);
    float fGGX1 = geometry_schlick_ggx(fNdotV, fRoughness);
    float fGGX2 = geometry_schlick_ggx(fNdotL, fRoughness);
    
    return fGGX1 * fGGX2;
}

vec3 fresnel_schlick(float fCT, vec3 vF0){
    return vF0 + (1.0 - vF0) * pow(clamp(1.0 - fCT, 0.0, 1.0), 5.0);
}

vec2 cube_uv(vec3 vNormal){
    // Calculate which 'face' we are on:
    vec3 vAbs = abs(vNormal);
    vec2 vUV = vec2(0);
    int iFaceIndex = 0; // X+, X-, Y+, Y-, Z+, Z-
    float fMa;
    if (vAbs.z >= vAbs.x && vAbs.z >= vAbs.y){
        iFaceIndex = vNormal.z < 0.0 ? 5 : 4;
        fMa = 0.5 / vAbs.z;
        vUV.x = (vNormal.z < 0.0 ? -vNormal.x : vNormal.x);
        vUV.y = -vNormal.y;
    }
    else if (vAbs.y >= vAbs.x){
        iFaceIndex = vNormal.y < 0.0 ? 3 : 2;
        fMa = 0.5 / vAbs.y;
        vUV.x = vNormal.x;
        vUV.y = (vNormal.y < 0.0 ? -vNormal.z : vNormal.z);
    }
    else {
        iFaceIndex = vNormal.x < 0.0 ? 1 : 0;
        fMa = 0.5 / vAbs.x;
        vUV.x = (vNormal.x < 0.0 ? vNormal.z : -vNormal.z);
        vUV.y = -vNormal.y;
    }
    vUV = vUV * fMa + 0.5;
    
    // Scale and map to single texture:
    float fDX = 0.25;
    float fDY = 1.0 / 3.0;
    vUV = vUV * vec2(fDX, fDY);
    if (iFaceIndex == 0)            // +X
        vUV += vec2(fDX, fDY);
    else if (iFaceIndex == 1)       // -X
        vUV += vec2(fDX * 3.0, fDY);
    else if (iFaceIndex == 2)       // +Y
        vUV += vec2(fDX, 0.0);
    else if (iFaceIndex == 3)       // -Y
        vUV += vec2(fDX, fDY * 2.0);
    else if (iFaceIndex == 4)       // +Z
        vUV += vec2(fDX * 2.0, fDY);
    else                            // -Z
        vUV += vec2(0.0, fDX);
    
    return vUV;
}

// https://stackoverflow.com/questions/59411510/convert-sampler2d-into-samplercube
/// Takes a 3D directional vector and converts it to a UV coordinate on a cube map
// vec2 cube_map_uv(vec3 vDirection){
//     vec2 vT = vec2(0, 0);
//     vDirection = normalize(vDirection) / sqrt(2.0);
//     vDirection.x = -vDirection.x;
//     vDirection.z = -vDirection.z;
//     vec3 vQ = abs(vDirection);
//     if (vQ.x >= vQ.y && vQ.x >= vQ.z){
//         vT.x = 0.5 - vDirection.z / vDirection.x;
//         vT.y = 0.5 - vDirection.y / vDirection.x;
//     }
//     else if (vQ.y >= vQ.x && vQ.y >= vQ.z){
//         vT.x = 0.5 - vDirection.x / vDirection.y;
//         vT.y = 0.5 - vDirection.z / vDirection.y;
//     }
//     else {
//         vT.x = 0.5 - vDirection.x / vDirection.z;
//         vT.y = 0.5 - vDirection.z / vDirection.z;
//     }
//     return vT;
// }

// vec4 depth_to_view(float fDepth){
//     float fZ = fDepth * 2.0 - 1.0;
//     vec4 vClip = vec4(v_vTexcoord.xy * 2.0 - 1.0, fZ, 1.0);
//     vec4 vViewPos = u_mInvProj * vClip;
//     vViewPos /= vViewPos.w;
//     return vViewPos;
// }

void main()
{
    vec4 vAlbedo = texture2D(u_sAlbedo, v_vTexcoord);
    if (u_iTranslucentPass <= 0){
/// @stub   Use a dynamic alpha cutoff (it is specified in glTF spec; 0.5 is the default)
        if (vAlbedo.a < 0.5)
/// @stub   Use a better option than 'discard'
            discard;
        else
            vAlbedo.a = 1.0;
    }
    
    vec3 vNormal = normalize(texture2D(u_sNormal, v_vTexcoord).xyz * 2.0 - 1.0);
    vec3 vPBR = texture2D(u_sPBR, v_vTexcoord).rgb; // Spec, Rough, Met
    
    float fSpecular = vPBR.r;
    float fRoughness = vPBR.g;
    float fMetallic = vPBR.b;
    
   // Specular calculations:
    vec3 vHalf = normalize(vView + u_vLightNormal);
    /// @stub make specular adjust F0 by calculating "Index of Refraction" where 0.5 = 0.04
    vec3 vF0 = vec3(0.04);
    vF0 = mix(vF0, vAlbedo.rgb, fMetallic);
    vec3 vRadiance = u_vLightColor;  // Always the color, as directional doesn't have attenuation
    float fNDF = distribution_ggx(vNormal, vHalf, fRoughness);
    float fG = geometry_smith(vNormal, u_vLightNormal, fRoughness);
    vec3 vF = fresnel_schlick(max(dot(vHalf, vView), 0.0), vF0);
    
/// @stub   Add support for cube-mapping (even if just environment)
    vec3 vKD = mix(vec3(1.0) - vF, vec3(0.0), fMetallic);
    // vec3 vKD = vec3(1.0) - vF; // <- Simplified; still adds color w/ metallic
    vec3 vNumerator = fNDF * fG * vF;
    float fDenominator = 4.0 * max(dot(vNormal, vView), 0.0) * max(dot(vNormal, u_vLightNormal), 0.0);
    vec3 vSpecular = vNumerator / max(fDenominator, 0.00001);
    float fNdotL = max(dot(vNormal, u_vLightNormal), 0.0);
    vAlbedo.rgb = (vKD * vAlbedo.rgb / fPI + vSpecular) * vRadiance * fNdotL;
    
    gl_FragColor = vAlbedo;
}
