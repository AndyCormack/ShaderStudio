precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_speed;
uniform vec3 u_colorA;
uniform vec3 u_colorB;

varying vec2 vUv;

void main() {
    vec2 p = vUv * 6.0;
    p.x *= u_resolution.x / max(u_resolution.y, 1.0);
    float t = u_time * u_speed;

    float v = sin(p.x + t)
            + sin(p.y + t * 0.7)
            + sin(p.x + p.y + t * 0.5)
            + sin(length(p - 3.0) * 1.5 - t);
    float m = 0.5 + 0.5 * sin(v);

    gl_FragColor = vec4(mix(u_colorA, u_colorB, m), 1.0);
}
