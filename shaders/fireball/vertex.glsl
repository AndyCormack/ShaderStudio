precision highp float;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 modelMatrix;
uniform float u_time;
uniform float u_churn;
uniform float u_displace;   // amplitude of the burnt-crust displacement

attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;

// Original (undisplaced) object position keeps the surface noise domain stable.
varying vec3 vLocalPos;
varying vec3 vWorldNormal;
varying vec3 vWorldPos;
varying vec2 vUv;
varying float vCrust;       // crust height passed to the fragment for shading

// ---------- compact 3D value-noise fbm (for the displacement map) ----------
float h13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
float vn(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(h13(i + vec3(0.0, 0.0, 0.0)), h13(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(h13(i + vec3(0.0, 1.0, 0.0)), h13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
        mix(mix(h13(i + vec3(0.0, 0.0, 1.0)), h13(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(h13(i + vec3(0.0, 1.0, 1.0)), h13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
        f.z);
}
float fbm(vec3 p) {
    float a = 0.5;
    float s = 0.0;
    for (int i = 0; i < 4; i++) {
        s += a * vn(p);
        p *= 2.03;
        a *= 0.5;
    }
    return s;
}

void main() {
    vLocalPos = position;

    // Static, uneven crust height — coarse plates plus finer grit. Kept static
    // (no time) so the crust surface never warps.
    float crust = fbm(position * 3.5);
    crust += 0.5 * fbm(position * 8.0);
    crust /= 1.5;
    vCrust = crust;

    // Push the surface out along its normal so the crust reads as physically uneven.
    vec3 displaced = position + normal * (crust - 0.5) * u_displace;

    vWorldPos = (modelMatrix * vec4(displaced, 1.0)).xyz;
    vWorldNormal = normalize(mat3(modelMatrix) * normal);
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(displaced, 1.0);
}
