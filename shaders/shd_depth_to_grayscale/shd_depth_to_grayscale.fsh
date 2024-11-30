uniform vec2 u_vZClip;

varying vec2 v_vTexcoord;
varying vec4 v_vColor;

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
    float fDepth = texture2D(gm_BaseTexture, v_vTexcoord).r;
    fDepth = (1.0 - linearize_depth(fDepth));

    gl_FragColor = v_vColor * vec4(fDepth, fDepth, fDepth, 1.0);
}
