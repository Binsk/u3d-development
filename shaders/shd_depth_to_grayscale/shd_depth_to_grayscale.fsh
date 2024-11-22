varying vec2 v_vTexcoord;
varying vec4 v_vColor;

void main()
{
    float fDepth = texture2D(gm_BaseTexture, v_vTexcoord).r;
    fDepth = 1.0 - fDepth;

    gl_FragColor = v_vColor * vec4(fDepth, fDepth, fDepth, 1.0);
}
