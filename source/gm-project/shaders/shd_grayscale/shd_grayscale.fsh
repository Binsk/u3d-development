uniform sampler2D u_sInput;
varying vec2 v_vTexcoord;

void main()
{
    vec4 vColor = texture2D(u_sInput, v_vTexcoord);
    float fLuminance = sqrt(0.299 * vColor.r * vColor.r + 0.587 * vColor.g * vColor.g + 0.114 * vColor.b * vColor.b);
    gl_FragColor = vec4(fLuminance, fLuminance, fLuminance, vColor.a);
}
