precision highp float;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
uniform float u_time;
uniform float u_intensity;

attribute vec3 position;
attribute vec3 normal;

varying vec3 vNormal;
varying float vHeat;

void main() {
    float wob = sin(position.y * 4.0 + u_time * 3.0)
              * sin(position.x * 5.0 - u_time * 2.0)
              * sin(position.z * 6.0 + u_time * 2.5);
    float disp = wob * 0.15 * u_intensity;

    vNormal = normal;
    vHeat = clamp(0.5 + wob * u_intensity, 0.0, 1.0);

    vec3 displaced = position + normal * disp;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(displaced, 1.0);
}
