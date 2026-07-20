precision highp float;

uniform float u_time;

varying vec3 vNormal;

void main() {
    vec3 base = normalize(vNormal) * 0.5 + 0.5;
    float pulse = 0.5 + 0.5 * sin(u_time * 2.0);
    gl_FragColor = vec4(base * (0.6 + 0.4 * pulse), 1.0);
}
