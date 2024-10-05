varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    float fDepth = 1.0 - texture2D(gm_BaseTexture, v_vTexcoord).r;
    
        // The depth clear is backwards so we just flip it for visualization purposes:
    // if (fDepth >= 1.0)
    //     fDepth = 0.0;
        
    gl_FragColor = vec4(fDepth, fDepth, fDepth, 1.0);
}
