uniform sampler2D u_sInput;
uniform float u_fThreshold;

varying vec2 v_vTexcoord;

void main()
{
    vec3 vColor = texture2D(u_sInput, v_vTexcoord).rgb;
    float fLuminance = sqrt(0.299 * vColor.r * vColor.r + 0.587 * vColor.g * vColor.g + 0.114 * vColor.b * vColor.b);
    if (fLuminance < u_fThreshold)
        discard;
    
    gl_FragColor = vec4(vColor.rgb, 1.0);
}
