varying vec2 v_vTexcoord;
varying vec4 v_vColor;

void main()
{
    gl_FragData[0] = v_vColor * texture2D(gm_BaseTexture, v_vTexcoord);
}
