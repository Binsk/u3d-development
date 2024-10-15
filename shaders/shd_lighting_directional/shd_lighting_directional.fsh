uniform sampler2D u_sAlbedo;
uniform sampler2D u_sNormal;
uniform sampler2D u_sPBR;
uniform sampler2D u_sEnvironment;
uniform sampler2D u_sView;
uniform sampler2D u_sDepth; // Only used w/ shadows
uniform sampler2D u_sShadow;

uniform vec3 u_vLightNormal;
uniform vec3 u_vLightColor;
uniform int u_iEnvironment;

uniform vec2 u_vTexelSize;
uniform int u_iShadows;
uniform float u_fShadowBias;
uniform mat4 u_mShadow; // World-to-projection space in the shadow map
uniform mat4 u_mInvProj;
uniform mat4 u_mInvView;

varying vec2 v_vTexcoord;

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

float geometry_smith(vec3 vNormal, vec3 vView, vec3 vLight, float fRoughness){
    float fNdotV = max(dot(vNormal, vView), 0.0);
    float fNdotL = max(dot(vNormal, vLight), 0.0);
    float fGGX1 = geometry_schlick_ggx(fNdotV, fRoughness);
    float fGGX2 = geometry_schlick_ggx(fNdotL, fRoughness);
    
    return fGGX1 * fGGX2;
}

vec3 fresnel_schlick(float fCT, vec3 vF0){
    return vF0 + (1.0 - vF0) * pow(clamp(1.0 - fCT, 0.0, 1.0), 5.0);
}

// https://www.gamedev.net/forums/topic/687535-implementing-a-cube-map-lookup-function/5337475/
vec2 cube_uv(vec3 vNormal){
    // Calculate which 'face' we are on:
    vec3 vAbs = abs(vNormal);
    vec2 vUV = vec2(0);
    int iFaceIndex = 0; // X+, X-, Y+, Y-, Z+, Z-
    float fMa;
    if (vAbs.z >= vAbs.x && vAbs.z >= vAbs.y){
        iFaceIndex = vNormal.z < 0.0 ? 5 : 4;
        fMa = 0.5 / vAbs.z;
        vUV.x = (vNormal.z < 0.0 ? vNormal.x : -vNormal.x);
        vUV.y = -vNormal.y;
    }
    else if (vAbs.y >= vAbs.x){
        iFaceIndex = vNormal.y < 0.0 ? 3 : 2;
        fMa = 0.5 / vAbs.y;
        vUV.x = vNormal.z;
        vUV.y = (vNormal.y < 0.0 ? -vNormal.x : vNormal.x);
    }
    else {
        iFaceIndex = vNormal.x < 0.0 ? 1 : 0;
        fMa = 0.5 / vAbs.x;
        vUV.x = (vNormal.x < 0.0 ? -vNormal.z : vNormal.z);
        vUV.y = -vNormal.y;
    }
    vUV = vUV * fMa + 0.5;
    
    // Scale and map to single texture:
    float fDX = 0.25;
    float fDY = 1.0 / 3.0;
    vUV = vUV * vec2(fDX, fDY); // Scale to the proper sub-size of the image
        // Determine UV offset based on face
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
        vUV += vec2(0.0, fDY);
    
    return vUV;
}

// Returns a fake mip sample given an absolute mip level between [0..6)
vec4 texture2DMip(sampler2D sTexture, vec2 vUV, int iMip){
    float fDx = 1.0 / 1.5;
    float fDy = 1.0;
    fDx *= pow(0.5, float(iMip));
    fDy *= pow(0.5, float(iMip));
    
    float fX = (iMip == 0 ? 0.0 : 1.0 / 1.5);
    float fY = (iMip == 0 ? 0.0 : 1.0 - fDy - fDy);
    vec2 vUVMip = mix(vec2(fX, fY), vec2(fX + fDx, fY + fDy), vUV);
    return texture2D(sTexture, vUVMip);
}

vec3 depth_to_world(float fDepth, vec2 vUV){
    float fZ = fDepth * 2.0 - 1.0;
    vec4 vClipPos = vec4(vUV.xy * 2.0 - 1.0, fZ, 1.0);
    vec4 vViewPos = u_mInvProj * vClipPos;
    vViewPos /= vViewPos.w;
    return (u_mInvView * vViewPos).xyz;
}

/// Returns the amount that is in shadow (0 or 1)
float calculate_shadow(){
    float fShadow;
    for (int i = -2; i <= 2; ++i){
        for (int j = -2; j <= 2; ++j){
            // Calculate fragment position in world space:
            vec2 vUV = v_vTexcoord + (vec2(i, j) * u_vTexelSize);
            vec3 vPosition = depth_to_world(texture2D(u_sDepth, vUV).r , vUV);
            // Convert it into the light's projection space:
            vec3 vLPosition = (u_mShadow * vec4(vPosition.xyz, 1.0)).xyz * 0.5 + 0.5; // Note, no need to div by w due to ortho projection
            
            // Sample against light's depth buffer and return if there is a shadow
            if (texture2D(u_sShadow, vLPosition.xy).r < vLPosition.z - u_fShadowBias)
                fShadow += 1.0;
        }
    }
    
    return fShadow / 25.0;
}

void main()
{
    float fShadow = 0.0;
    if (u_iShadows > 0){
        fShadow = calculate_shadow();
        if (fShadow >= 1.0)
            discard;
    }
    
    vec4 vAlbedo = texture2D(u_sAlbedo, v_vTexcoord);
    vec3 vNormal = normalize(texture2D(u_sNormal, v_vTexcoord).xyz * 2.0 - 1.0);
    vec3 vPBR = texture2D(u_sPBR, v_vTexcoord).rgb; // Spec, Rough, Met
    
    float fSpecular = vPBR.r;
    float fRoughness = vPBR.g;
    float fMetallic = vPBR.b;
    
    vec3 vView = normalize(texture2D(u_sView, v_vTexcoord).rgb * 2.0 - 1.0);
    vView = -vView;
    vec3 vHalf = normalize(vView + u_vLightNormal);
    
        // Calculate environment reflections, if enabled:
    vec3 vCubeColor = vec3(0);   // If no environment map; just reflect 'black'
    if (u_iEnvironment > 0){
        vec2 vCube = cube_uv(normalize(reflect(-vView, vNormal)));
        vCubeColor = texture2DMip(u_sEnvironment, vCube, 0).rgb;
/// @stub   Add in roughness sampling so roughness affects reflection 
    }
    
/// @stub make specular adjust F0 by calculating "Index of Refraction" where 0.5 = 0.04
    vec3 vF0 = vec3(0.04);
    vF0 = mix(vF0, vAlbedo.rgb, fMetallic);
    vec3 vRadiance = u_vLightColor;  // Always the color, as directional doesn't have attenuation
    float fNDF = distribution_ggx(vNormal, vHalf, fRoughness);
    float fG = geometry_smith(vNormal, vView, u_vLightNormal, fRoughness);
    vec3 vF = fresnel_schlick(max(dot(vHalf, vView), 0.0), vF0);
    
    vec3 vKD = mix(vec3(1.0) - vF, vCubeColor, fMetallic);
    // vec3 vKD = vec3(1.0) - vF; // <- Simplified; still adds color w/ metallic (stylistic option if no environment?)
    vec3 vNumerator = fNDF * fG * vF;
    float fDenominator = 4.0 * max(dot(vNormal, vView), 0.0) * max(dot(vNormal, u_vLightNormal), 0.0);
    vec3 vSpecular = vNumerator / max(fDenominator, 0.00001);
    float fNdotL = max(dot(vNormal, u_vLightNormal), 0.0);
    vAlbedo.rgb = (vKD * vAlbedo.rgb / fPI + vSpecular) * vRadiance * fNdotL * (1.0 - fShadow);
    
    gl_FragColor = vAlbedo;
}
