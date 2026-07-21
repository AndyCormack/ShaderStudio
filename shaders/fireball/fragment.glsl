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

// One tier of turbulence (a crease field) — low values are the crack creases.
float turbTier(vec3 p) {
    float t = 0.0;
    float a = 0.5;
    float f = 1.0;
    for (int i = 0; i < 4; i++) {
        t += a * abs(vnoise(p * f) * 2.0 - 1.0);
        f *= 2.05;
        a *= 0.5;
    }
    return t;
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
    vec3 cDeep   = u_emberColor * 0.45;                          // near-black blood red
    vec3 cEmber  = u_emberColor;                                 // deep red
    vec3 cRed    = u_emberColor * 2.7;                           // rich glowing red
    vec3 cOrange = mix(u_emberColor, u_coreColor, 0.42) * 1.9;   // deep orange
    vec3 cAmber  = mix(u_emberColor, u_coreColor, 0.78) * 2.0;   // amber
    vec3 cCore   = u_coreColor * 1.9;                            // gold
    vec3 cHot    = vec3(3.4, 3.0, 2.2);                          // white-hot core
    // A rich, many-stopped body — near-black red → deep red → glowing red →
    // orange → amber → gold — then a NARROW white core so the bright tendril
    // centres fall off quickly into deep orangey reds.
    vec3 c = cRock;
    c = mix(c, cDeep,   smoothstep(0.02, 0.08, h));
    c = mix(c, cEmber,  smoothstep(0.08, 0.18, h));
    c = mix(c, cRed,    smoothstep(0.18, 0.34, h));
    c = mix(c, cOrange, smoothstep(0.34, 0.50, h));
    c = mix(c, cAmber,  smoothstep(0.50, 0.68, h));
    c = mix(c, cCore,   smoothstep(0.68, 0.85, h));
    c = mix(c, cHot,    smoothstep(0.91, 1.00, h));
    return c;
}

void main() {
    vec3 N = normalize(vWorldNormal);

    // Static organic warp, then a RIGID scroll up the Y axis — a pure domain
    // translation, so the whole cloud + cracks slide up as one sheet (stable
    // molten flow, no boiling). u_churn only shimmers brightness.
    vec3 q = warp(vLocalPos * u_scale) - vec3(0.0, u_time * u_scroll, 0.0);

    // --- Layered branching lava veins: three tiers of turbulence creases at
    // rising density/scale — bold primary rivers, medium branches, fine capillary
    // tendrils — glowing through dark cracked rock. Scrolling q rigidly slides
    // the whole network up as one sheet (stable molten flow, no boiling). ---
    // Brightness variation times a large-scale temperature field, so whole
    // regions run hotter (amber/gold) or cooler (deep red) — richer, varied lava.
    float crackVar = (0.4 + 0.8 * fbm(q * 0.6 + 5.0)) * (0.7 + 0.65 * fbm(q * 0.22 + 50.0));
    float shimmer = 0.85 + 0.15 * sin(u_time * u_churn * 2.5 + fbm(q * 1.1) * TAU);

    float t1 = turbTier(q);                        // primary rivers (coarse)
    float t2 = turbTier(q * 2.3 + 11.0);           // secondary branches
    float t3 = turbTier(q * 4.9 + 27.0);           // fine capillary tendrils

    // Bright thin vein cores from each tier's creases; finer tiers thinner + dimmer.
    float c1 = 1.0 - smoothstep(0.0, u_crackWidth, t1);
    float c2 = (1.0 - smoothstep(0.0, u_crackWidth * 0.65, t2)) * 0.8;
    float c3 = (1.0 - smoothstep(0.0, u_crackWidth * 0.45, t3)) * 0.55;
    float veins = max(c1, max(c2, c3));

    // A wider connected molten base from the primary tier joins the veins into
    // rivers with a deep-red glow (instead of isolated spots).
    float base = 1.0 - smoothstep(0.0, u_crackWidth * 3.0, t1);

    // Heat drives the multi-stop ramp: bright white cores fall off quickly into
    // the deep-red connected base, then cold dark rock.
    float heat = (veins * 0.95 + base * 0.5) * crackVar * shimmer * u_intensity;

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
    col += fireGradient(rim * 1.3) * u_rimColor * rim * 0.6;

    // HDR cracks/rim (values >1) pass through to the bloom pass (D21).
    gl_FragColor = vec4(col, 1.0);
}
