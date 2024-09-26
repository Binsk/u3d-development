varying vec2 v_vTexcoord;

vec3 to_srgb(vec3 vColor){
	bvec3 bCutoff = lessThan(vColor, vec3(0.0031308));
	vec3 vHigher = vec3(1.055) * pow(abs(vColor), vec3(1.0 / 2.4) - vec3(0.055));
	vec3 vLower = vColor * vec3(12.92);
	return mix(vHigher, vLower, vec3(bCutoff));
}

vec4 to_srgb(vec4 vColor){
	return vec4(to_srgb(vColor.rgb), vColor.a);
}

void main()
{
    gl_FragColor = to_srgb(texture2D(gm_BaseTexture, v_vTexcoord));
}
