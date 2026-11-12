shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

void fragment() {
    float wave_a = sin(UV.x * 34.0 + TIME * 0.8);
    float wave_b = sin(UV.y * 27.0 - TIME * 0.55);
    float ripple = (wave_a + wave_b) * 0.025;
    vec3 deep = vec3(0.025, 0.16, 0.22);
    vec3 shallow = vec3(0.09, 0.34, 0.39);
    ALBEDO = mix(deep, shallow, 0.45 + ripple);
    METALLIC = 0.12;
    ROUGHNESS = 0.19;
    SPECULAR = 0.82;
}
