uniform sampler2D u_sAlbedo;
uniform float u_fAlphaCutoff;

varying vec2 v_vTexcoord;

void main()
{
    float fAlpha = texture2D(u_sAlbedo, v_vTexcoord).a;
    if (fAlpha < u_fAlphaCutoff)
        discard;
        
    gl_FragColor.r = gl_FragCoord.z;
}
