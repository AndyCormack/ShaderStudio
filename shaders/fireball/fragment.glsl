precision highp float;

uniform vec3 cameraPosition; // world-space camera, supplied by three for the mesh
uniform float u_time;
uniform float u_intensity;   // overall heat / HDR push into the highlights
uniform float u_churn;       // brightness shimmer speed (does NOT move the pattern)
uniform float u_scroll;      // speed the whole texture scrolls up the Y axis
uniform float u_scale;       // scale of the crack network
uniform float u_crackWidth;  // seam thickness of the glowing cracks
uniform float u_crust;       // strength/visibility of the rough rock crust
uniform vec3 u_coreColor;    // hot core / gold band of the ramp
uniform vec3 u_emberColor;   // deep low-heat ember (the red glow)
uniform vec3 u_crustColor;   // rough cold rock (cold end of the ramp)
uniform vec3 u_rimColor;     // fiery Fresnel rim tint

varying vec3 vLocalPos;
varying vec3 vWorldNormal;
varying vec3 vWorldPos;
varying vec2 vUv;
varying float vCrust;

const float TAU = 6.2831853;

float saturate(float x) { return clamp(x, 0.0, 1.0); }

// ---------- hash + 3D value noise + fbm ----------
float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
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
    for (int i = 0; i < 5; i++) {
        s += a * vnoise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return s;
}

// ---------- ridged fractal (used for the rough rock crust) ----------
float ridged(vec3 p) {
    float sum = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < 6; i++) {
        float n = 1.0 - abs(vnoise(p * freq) * 2.0 - 1.0);
        n = n * n;
        sum += n * amp;
        freq *= 1.92;
        amp *= 0.55;
    }
    return sum;
}

// Static domain warp (no time) — organic, but never moves on its own.
vec3 warp(vec3 p) {
    vec3 q = vec3(vnoise(p + vec3(0.0, 1.0, 2.0)),
                  vnoise(p + vec3(5.2, 1.3, 0.8)),
                  vnoise(p + vec3(1.7, 9.2, 3.4)));
    return p + 0.5 * (q - 0.5);
}

// ---------- HDR fire ramp (used by the rim). ----------
vec3 fireGradient(float h) {
    h = saturate(h);
    vec3 c0 = u_emberColor * 0.10;
    vec3 c1 = u_emberColor;
    vec3 c2 = mix(u_emberColor, u_coreColor, 0.55) * 1.3;
    vec3 c3 = u_coreColor * 1.6;
    vec3 c4 = vec3(3.00, 2.60, 1.90);
    vec3 c = mix(c0, c1, smoothstep(0.00, 0.15, h));
    c = mix(c, c2, smoothstep(0.12, 0.38, h));
    c = mix(c, c3, smoothstep(0.35, 0.72, h));
    c = mix(c, c4, smoothstep(0.90, 1.00, h));
    return c;
}

// ---------- Multi-stop lava ramp: one heat scalar drives the whole surface —
// cold rough rock -> deep-red ember glow -> orange -> gold core -> white-hot.
// rockShade is the rough rock texture applied to the cold stop. ----------
vec3 lavaRamp(float h, float rockShade) {
    h = saturate(h);
    vec3 cRock   = u_crustColor * rockShade;                     // cold rough rock
    vec3 cEmber  = u_emberColor;                                 // deep red glow
    vec3 cOrange = mix(u_emberColor, u_coreColor, 0.55) * 1.3;   // orange
    vec3 cCore   = u_coreColor * 1.5;                            // gold
    vec3 cHot    = vec3(3.0, 2.6, 1.9);                          // white-hot crack
    vec3 c = cRock;
    c = mix(c, cEmber,  smoothstep(0.02, 0.20, h));
    c = mix(c, cOrange, smoothstep(0.20, 0.48, h));
    c = mix(c, cCore,   smoothstep(0.48, 0.76, h));
    c = mix(c, cHot,    smoothstep(0.82, 1.00, h));
    return c;
}

void main() {
    vec3 N = normalize(vWorldNormal);

    // Static organic warp, then a RIGID scroll up the Y axis — a pure domain
    // translation, so the whole cloud + cracks slide up as one sheet (stable
    // molten flow, no boiling). u_churn only shimmers brightness.
    vec3 q = warp(vLocalPos * u_scale) - vec3(0.0, u_time * u_scroll, 0.0);

    // --- Fractal cloud cracks: domain-warped TURBULENCE (sum of abs-noise). The
    // high folds are dark cold rock; where the turbulence dips it glows as cloudy
    // molten lava. Scrolling q rigidly slides the whole cloud up as one sheet
    // (stable molten flow, no boiling). ---
    float turb = 0.0;
    float amp = 0.5;
    float fr = 1.0;
    for (int oi = 0; oi < 6; oi++) {
        turb += amp * abs(vnoise(q * fr) * 2.0 - 1.0);
        fr *= 2.05;
        amp *= 0.5;
    }
    float d = turb;

    // Organic brightness variation + gentle brightness-only shimmer.
    float crackVar = 0.4 + 0.8 * fbm(q * 0.6 + 5.0);
    float shimmer = 0.85 + 0.15 * sin(u_time * u_churn * 2.5 + fbm(q * 1.1) * TAU);

    // Heat: bright cloudy lava where the turbulence dips + a red-glow falloff
    // onto the rock, 0 out on the high folds. Drives the multi-stop lava ramp.
    float coreC = pow(1.0 - smoothstep(0.0, u_crackWidth, d), 1.6);
    float glowC = 1.0 - smoothstep(0.0, u_crackWidth * 6.0, d);
    float heat = (coreC * 0.7 + glowC * 0.45) * crackVar * shimmer * u_intensity;

    // --- Rough rock texture — the cold end of the ramp. ---
    float rough = ridged(q * 3.0 + 20.0);
    float grain = fbm(q * 12.0 - 4.0);
    float fine = vnoise(q * 42.0);
    float speck = vnoise(q * 95.0);
    float crustTex = smoothstep(0.22, 0.78, rough * 0.5 + grain * 0.35 + fine * 0.15);
    crustTex = mix(crustTex, fine, 0.28);
    float rockShade = (0.35 + 1.0 * crustTex) * (0.6 + 0.6 * fine);
    rockShade *= (1.0 - smoothstep(0.5, 0.82, speck) * 0.6);   // dark pits
    rockShade = mix(1.0, rockShade, u_crust);

    vec3 col = lavaRamp(heat, rockShade);

    // --- Fiery Fresnel rim — the silhouette glow. ---
    vec3 V = normalize(cameraPosition - vWorldPos);
    float fres = pow(1.0 - saturate(dot(N, V)), 3.2);
    vec2 np = normalize(vLocalPos).xy * 3.0;
    float rflick = 0.75 + 0.25 * vnoise(vec3(np * 2.0, u_time * u_churn * 0.5));
    float rim = fres * rflick;
    col += fireGradient(rim * 1.3) * u_rimColor * rim * 1.3;

    // HDR cracks/rim (values >1) pass through to the bloom pass (D21).
    gl_FragColor = vec4(col, 1.0);
}
