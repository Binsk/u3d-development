precision highp float;

uniform sampler2D u_sInput; // Final color
uniform sampler2D u_sDepth;
uniform int u_iRenderStages;

uniform vec4 u_vColor;
uniform vec2 u_vRange;  // Start / End ranges
uniform vec2 u_vZClip;
uniform int u_iAlphaOnly;

varying vec2 v_vTexcoord;

float linearize_depth(float fDepth)
{
    #ifndef _YY_HLSL11_
    fDepth = fDepth * 2.0 - 1.0;
    #endif
    
    float fClip = (u_vZClip.y / u_vZClip.x);
    return 1.0 / ((1.0 - fClip) * fDepth + fClip);
}

void main()
{
    float fDepth = 1.0;
    fDepth = min(fDepth, texture2D(u_sDepth, v_vTexcoord).r);
    
    fDepth = linearize_depth(fDepth);
    
    float fLerp = clamp((fDepth - u_vRange.x) / (u_vRange.y - u_vRange.x), 0.0, 1.0);
    if (u_iAlphaOnly == 0)
        gl_FragColor = mix(texture2D(u_sInput, v_vTexcoord), u_vColor, fLerp);
    else{
        vec4 vColor = texture2D(u_sInput, v_vTexcoord);
        gl_FragColor = vec4(vColor.rgb, mix(vColor.a, u_vColor.a, fLerp));
    }
}
