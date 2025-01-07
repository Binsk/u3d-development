precision highp float;

uniform sampler2D u_sInput; // Input color
uniform sampler2D u_sEnvironment;   // Cube-map to sample
uniform sampler2D u_sView;          // View vectors in world-space
uniform int u_iMipCount;            // Used to detect if a PBR texture was passed

varying vec2 v_vTexcoord;

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
    
    if (u_iMipCount > 0)    // Only grab non-blurred half of texture if PBR
        vUV.x *= 0.5;
    
    return vUV;
}

void main()
{
    /// @stub   Assumes skybox is in linear space! A toggle will be added later
    vec4 vColor = texture2D(u_sInput, v_vTexcoord);
    vec3 vView = texture2D(u_sView, v_vTexcoord).rgb * 2.0 - 1.0;
    vec4 vCubeColor = texture2D(u_sEnvironment, cube_uv(vView));
    
    /// @note   The color blending may cause the primary layer to go darker than
    ///         expected due to the HDR value scaling. Need to figure out a way around
    ///         this visual issue.
    if (vColor.a < 1.0)
        vColor = (vColor * vColor.a) + (vCubeColor * (1.0 - vColor.a));
    else
        vColor.a = 1.0;
        
    gl_FragColor = vColor;
}
