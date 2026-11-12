shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 world_position;
varying vec3 world_normal;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    vec2 p = world_position.xz * 0.075;
    float broad = noise2(p);
    float detail = noise2(p * 4.2);
    float slope = 1.0 - clamp(dot(normalize(world_normal), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);

    vec3 grass_dark = vec3(0.105, 0.175, 0.105);
    vec3 grass_light = vec3(0.255, 0.335, 0.165);
    vec3 moss = vec3(0.32, 0.30, 0.16);
    vec3 stone = vec3(0.255, 0.285, 0.29);

    vec3 ground = mix(grass_dark, grass_light, smoothstep(0.22, 0.82, broad));
    ground = mix(ground, moss, smoothstep(0.58, 0.92, detail) * 0.35);
    ground = mix(ground, stone, smoothstep(0.34, 0.72, slope));
    ground *= 0.92 + detail * 0.13;

    ALBEDO = ground;
    ROUGHNESS = 0.94;
}
