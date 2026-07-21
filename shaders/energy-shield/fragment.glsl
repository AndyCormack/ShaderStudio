precision highp float;

uniform vec3 cameraPosition; // world-space camera, supplied by three for the mesh
uniform float u_time;
uniform float u_intensity;   // overall heat / HDR push into the highlights
uniform float u_churn;       // speed of the molten surface churn
uniform float u_scale;       // cell density of the lava network
uniform float u_crackWidth;  // seam thickness of the glowing veins
uniform float u_crust;       // strength/visibility of the burnt rock crust
uniform vec3 u_coreColor;    // hot core / gold band of the fire ramp
uniform vec3 u_emberColor;   // deep low-heat ember (the reds of the ramp)
uniform vec3 u_crustColor;   // charred rock filling the cell interiors
uniform vec3 u_rimColor;     // fiery Fresnel rim tint

varying vec3 vLocalPos;
varying vec3 vWorldNormal;
varying vec3 vWorldPos;
varying vec2 vUv;
varying float vCrust;   // burnt-crust height from the vertex displacement

const float TAU = 6.2831853;

float saturate(float x) { return clamp(x, 0.0, 1.0); }

// ---------- hashes ----------
float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
vec3 hash33(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453123);
}

// ---------- 3D value noise + fbm (domain warp + interior heat wash) ----------
float vnoise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash13(i + vec3(0.0, 0.0, 0.0)), hash13(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(hash13(i + vec3(0.0, 1.0, 0.0)), hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
        mix(mix(hash13(i + vec3(0.0, 0.0, 1.0)), hash13(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(hash13(i + vec3(0.0, 1.0, 1.0)), hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
        f.z);
}

float fbm(vec3 p) {
    float a = 0.5;
    float s = 0.0;
    for (int i = 0; i < 4; i++) {
        s += a * vnoise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return s;
}

// Bend the straight Voronoi seams into molten, blobby lobes (two octaves).
vec3 warp(vec3 p, float t) {
    vec3 q = vec3(
        vnoise(p + vec3(0.0, 1.0, 2.0) + 0.10 * t),
        vnoise(p + vec3(5.2, 1.3, 0.8) - 0.08 * t),
        vnoise(p + vec3(1.7, 9.2, 3.4) + 0.06 * t));
    vec3 r = vec3(
        vnoise(p * 2.1 + vec3(3.0, 0.0, 7.0) - 0.09 * t),
        vnoise(p * 2.1 + vec3(1.0, 8.0, 2.0) + 0.07 * t),
        vnoise(p * 2.1 + vec3(6.0, 4.0, 1.0) - 0.05 * t));
    return p + 0.85 * (q - 0.5) + 0.28 * (r - 0.5);
}

// ---------- animated 3D Worley: F1, F2 + winning cell id ----------
vec2 worley3(vec3 p, float warpT, out vec3 id) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    float f1 = 1e9;
    float f2 = 1e9;
    id = ip;
    for (int z = -1; z <= 1; z++) {
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                vec3 g = vec3(float(x), float(y), float(z));
                vec3 o = hash33(ip + g);
                o = 0.5 + 0.5 * sin(warpT + TAU * o);   // feature points orbit -> churn
                vec3 r = g + o - fp;
                float d = dot(r, r);
                if (d < f1) { f2 = f1; f1 = d; id = ip + g; }
                else if (d < f2) { f2 = d; }
            }
        }
    }
    return sqrt(vec2(f1, f2));
}

// Thin bright vein where F2 - F1 -> 0 (cell borders).
float veins(vec3 p, float warpT, float width, float sharp) {
    vec3 id;
    vec2 f = worley3(p, warpT, id);
    return pow(1.0 - smoothstep(0.0, width, f.y - f.x), sharp);
}

// ---------- HDR fire ramp driven by the ember + core colours: ember->hot
// mix->core->white, white only at the very top so seams read coloured. ----------
vec3 fireGradient(float h) {
    h = saturate(h);
    vec3 c0 = u_emberColor * 0.10;                        // near-black ember
    vec3 c1 = u_emberColor;                               // deep ember/red
    vec3 c2 = mix(u_emberColor, u_coreColor, 0.55) * 1.3; // hot orange mid
    vec3 c3 = u_coreColor * 1.6;                          // gold/core
    vec3 c4 = vec3(3.00, 2.60, 1.90);                     // white-hot (flares only)
    vec3 c = mix(c0, c1, smoothstep(0.00, 0.15, h));
    c = mix(c, c2, smoothstep(0.12, 0.38, h));
    c = mix(c, c3, smoothstep(0.35, 0.72, h));
    c = mix(c, c4, smoothstep(0.90, 1.00, h));
    return c;
}

void main() {
    vec3 N = normalize(vWorldNormal);
    float t = u_time * u_churn;

    // Sample in stable object space; domain-warp for molten curves.
    vec3 wp = warp(vLocalPos * u_scale, t);

    // Primary cells — keep F1 + cell id for interior glow & ember flicker.
    // u_scale maps directly to cell density here.
    vec3 id;
    vec2 f = worley3(wp, 0.10 * t, id);
    float border = f.y - f.x;
    float crack = pow(1.0 - smoothstep(0.0, u_crackWidth, border), 1.6);

    // A single finer capillary layer — subtle, so the crust stays molten, not electric.
    crack = max(crack, 0.55 * veins(wp * 2.2, 0.17 * t + 1.7, u_crackWidth * 0.75, 2.0));

    // Soft orange bloom halo hugging each vein (the glow the real photo has).
    float halo = 1.0 - smoothstep(0.0, u_crackWidth * 4.0, border);

    // Per-cell ember flicker: neighbours pulse out of sync (phase from cell id).
    float phase = hash13(id) * TAU;
    float pulse = pow(0.5 + 0.5 * sin(t * 3.0 + phase), 6.0);

    // Dim interior heat wash so cells breathe instead of reading as black holes.
    float heat = vnoise(wp * 1.5 + vec3(0.0, 0.0, 0.10 * t));
    float cellGlow = smoothstep(0.30, 0.95, heat) * (1.0 - f.x) * 0.28;

    // Temperature: veins land in the gold band; only pulses/flares reach white.
    float temp = (crack * 0.72 + cellGlow * 0.8) * u_intensity;
    temp += crack * pulse * 0.5 * u_intensity;

    // Burnt, crispy crust filling the cooler cell interiors — charred plates
    // (u_crustColor) with visible grit, and warm lava breathing through the
    // low crevices. u_crust scales how strongly the crust reads.
    float micro = fbm(wp * 2.6 + 7.0);
    float grit = vnoise(wp * 9.0 - t);
    float crevice = smoothstep(0.6, 0.0, vCrust);        // low crust = hot crevice
    vec3 rock = u_crustColor * (0.30 + 0.9 * micro);     // charred plates, visible variation
    rock *= (0.5 + 0.65 * grit);                         // crispy speckle
    rock += u_emberColor * 0.55 * crevice * smoothstep(0.3, 0.9, heat);  // lava in the crevices

    // Colour the body: fire in the seams, burnt rock across the interiors.
    vec3 col = fireGradient(temp);
    col += rock * (1.0 - crack) * u_crust;
    col += u_coreColor * halo * 0.18 * u_intensity;      // soft vein bloom halo

    // Fiery Fresnel rim — the silhouette ring of fire, flaring where cracks reach it.
    vec3 V = normalize(cameraPosition - vWorldPos);
    float fres = pow(1.0 - saturate(dot(N, V)), 3.2);
    vec2 np = normalize(vLocalPos).xy * 3.0;
    float flick = 0.70
                + 0.18 * vnoise(vec3(np * 2.0, t * 0.9))
                + 0.12 * vnoise(vec3(np * 5.0 - t * 0.6, t * 1.3));
    float rim = fres * flick;
    col += fireGradient(rim * 1.3) * u_rimColor * rim * (1.4 + crack * 1.4);

    // HDR seams/rim (values >1) pass through to the studio bloom pass (D21).
    gl_FragColor = vec4(col, 1.0);
}
