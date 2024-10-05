uniform sampler2D u_sAlbedo;
uniform sampler2D u_sSSAO;

uniform vec3 u_vAlbedo;
uniform int u_iSSAO;            // Whether or not we have SSAO enabled
uniform float u_fIntensity;
uniform vec2 u_vTexelSize;
uniform int u_iBlurSamples;
uniform float u_fBlurStride;

varying vec2 v_vTexcoord;

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

void main()
{
    vec4 vAlbedo = texture2D(u_sAlbedo, v_vTexcoord);
    float fSSAO = 1.0;
    if (u_iSSAO > 0)
        fSSAO = sample_ssao(u_iBlurSamples);
        
    gl_FragColor = vec4(vAlbedo.rgb * u_vAlbedo * u_fIntensity * fSSAO, vAlbedo.a);
}