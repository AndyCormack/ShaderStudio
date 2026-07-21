precision highp float;

uniform float u_time;
uniform vec3 u_coreColor;

varying vec3 vNormal;
varying float vHeat;

void main() {
    vec3 ember = vec3(0.75, 0.12, 0.0);
    float flicker = 0.92 + 0.08 * sin(u_time * 17.0);
    vec3 col = mix(ember, u_coreColor, vHeat) * flicker;
    gl_FragColor = vec4(col, 1.0);
}
