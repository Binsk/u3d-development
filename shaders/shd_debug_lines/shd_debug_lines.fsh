uniform sampler2D u_sDepth;
uniform vec3 u_vColor;
uniform vec2 u_vTexelSize;

float modulo(float fV, float fM){
    return fract(fV / fM) * fM;
}

void main()
{
    float fDepth = texture2D(u_sDepthOpaque, gl_FragCoord.xy * u_vTexelSize).r;
    vec3 vColor = u_vColor;

    if (gl_FragCoord.z > fDepth){
        if (modulo(gl_FragCoord.x + gl_FragCoord.y, 16.0) < 8.0)
          discard;
    }
    
    gl_FragColor = vec4(vColor.rgb, 1.0);
}
