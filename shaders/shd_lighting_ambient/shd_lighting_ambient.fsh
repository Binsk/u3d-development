uniform sampler2D u_sAlbedo;
uniform sampler2D u_sDepth;
uniform vec3 u_vAlbedo;
uniform int u_iTranslucency;
uniform float u_fIntensity;

varying vec2 v_vTexcoord;

/// @stub   Add in ambient occlusion for opaque instances
void main()
{
    vec4 vAlbedo = texture2D(u_sAlbedo, v_vTexcoord);
    gl_FragColor = vec4(vAlbedo.rgb * u_vAlbedo * u_fIntensity, vAlbedo.a);
}
