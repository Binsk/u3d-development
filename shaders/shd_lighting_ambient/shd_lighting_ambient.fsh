uniform sampler2D u_sAlbedo;
uniform sampler2D u_sSSAO;
uniform sampler2D u_sPBR;
uniform sampler2D u_sDepth;
uniform sampler2D u_sEnvironment;
uniform sampler2D u_sNormal;

uniform vec3 u_vAlbedo;
uniform int u_iSSAO;            // Whether or not we have SSAO enabled
uniform float u_fIntensity;
uniform vec2 u_vTexelSize;
uniform int u_iBlurSamples;
uniform float u_fBlurStride;

uniform mat4 u_mInvProj;
uniform mat4 u_mInvView;
uniform vec3 u_vCamPosition;

varying vec2 v_vTexcoord;

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

float sample_ssao(int iRadius){
    float fDx = u_vTexelSize.x * u_fBlurStride;
    float fDy = u_vTexelSize.y * u_fBlurStride;
    
    float fValue = 0.0;
    float fWeight = 0.0;
    for (int i = -iRadius; i <= iRadius; ++i){
        for (int j = -iRadius; j <= iRadius; ++j){
            vec2 vPos = vec2(i, j);
            vec2 vUV = vPos * vec2(fDx, fDy);
            
            float fLength = (1.0 / (length(vPos) + 1.0));
            fWeight += fLength;
            fValue += texture2D(u_sSSAO, v_vTexcoord + vUV).r * fLength;
        }
    }
    
    return fValue / fWeight;
}

vec3 depth_to_world(float fDepth, vec2 vUV){
    float fZ = fDepth * 2.0 - 1.0;
    vec4 vClipPos = vec4(vUV.xy * 2.0 - 1.0, fZ, 1.0);
    vec4 vViewPos = u_mInvProj * vClipPos;
    vViewPos /= vViewPos.w;
    vec4 vWorldPos = u_mInvView * vViewPos;
    return vWorldPos.xyz;
}

void main()
{
    vec4 vAlbedo = texture2D(u_sAlbedo, v_vTexcoord);
    float fSSAO = 1.0;
    if (u_iSSAO > 0)
        fSSAO = sample_ssao(u_iBlurSamples);
        
/// @stub   Add cube-mapping and whatnot for specularity simulation

    float fDepth = texture2D(u_sDepth, v_vTexcoord).r;
    vec3 vView = normalize(depth_to_world(fDepth, v_vTexcoord) - u_vCamPosition);
    vec3 vNormal = normalize(texture2D(u_sNormal, v_vTexcoord).xyz * 2.0 - 1.0);
    // vec2 vCube = cube_uv(normalize(reflect(vNormal, vView)));
    vec2 vCube = cube_uv(normalize(reflect(vView, vNormal)));
    vec3 vCubeColor = texture2D(u_sEnvironment, vCube).rgb;

    // vAlbedo.rgb = mix(vAlbedo.rgb, vec3(0), texture2D(u_sPBR, v_vTexcoord).b); // <- Temp just to help make it match the directional lighting
    vAlbedo.rgb = mix(vAlbedo.rgb, vCubeColor * vAlbedo.rgb, texture2D(u_sPBR, v_vTexcoord).b); // <- Temp just to help make it match the directional lighting
    gl_FragColor = vec4(vAlbedo.rgb * u_vAlbedo * u_fIntensity * fSSAO, vAlbedo.a);
}