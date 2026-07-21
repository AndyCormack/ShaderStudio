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
uniform float u_rimPower;    // Fresnel exponent — how far the rim encroaches from the edge
uniform int u_rimBlend;      // how the rim colour combines with the surface (0 add · 1 screen · 2 overlay · 3 mix)

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

vec3 srgb2lin(vec3 c) { return pow(c, vec3(2.2)); }   // hex sRGB -> linear working space

// Photoshop-style per-channel blend helpers (used by the rim blend-mode select).
vec3 overlayBlend(vec3 base, vec3 blend) {
    vec3 lo = 2.0 * base * blend;
    vec3 hi = 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);
    return mix(lo, hi, step(vec3(0.5), base));
}
vec3 softLightBlend(vec3 b, vec3 s) { return (1.0 - 2.0 * s) * b * b + 2.0 * s * b; } // pegtop
vec3 vividBlend(vec3 b, vec3 s) {
    vec3 burn = 1.0 - (1.0 - b) / max(2.0 * s, 1e-4);
    vec3 dodge = b / max(2.0 * (1.0 - s), 1e-4);
    return mix(burn, dodge, step(vec3(0.5), s));
}
vec3 pinBlend(vec3 b, vec3 s) {
    return mix(min(b, 2.0 * s), max(b, 2.0 * s - 1.0), step(vec3(0.5), s));
}

// ---------- Sharp-falloff lava ramp: one heat scalar runs the whole surface.
// A sharp peaked core (u_coreColor, default #FEF9BA) falls off QUICKLY to a
// glowing orange (u_emberColor, default #F76023), then MORE SLOWLY down to a
// deep red (#460808) before fading into the cold crust. ----------
vec3 lavaRamp(float h, float rockShade) {
    h = saturate(h);
    vec3 cRock = u_crustColor * rockShade;              // cold crust
    vec3 cDeep = srgb2lin(vec3(0.275, 0.031, 0.031));   // #460808 deep red
    vec3 cMid  = u_emberColor;                          // #F76023 glowing orange
    vec3 cPeak = u_coreColor;                           // #FEF9BA sharp peak
    // The lava GLOW colour (deep red -> orange -> peak), independent of the rock.
    vec3 lava = mix(cDeep, cMid, smoothstep(0.30, 0.62, h));
    lava = mix(lava, cPeak, smoothstep(0.86, 0.97, h));
    // How strongly the glow shows over the rock — a smooth ramp from zero so it
    // eases in gradually rather than a hard edge.
    float glow = smoothstep(0.0, 0.34, h);

    // Screen-blend the glow over the rock: the rock texture stays visible through
    // the red, and the glow fades softly into the cooling rock (no harsh edge).
    // HDR peak (>1 after the boost) still comes through for bloom.
    return 1.0 - (1.0 - cRock) * (1.0 - lava * glow);
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
    float crackVar = (0.62 + 0.55 * fbm(q * 0.6 + 5.0)) * (0.8 + 0.45 * fbm(q * 0.22 + 50.0));
    float shimmer = 0.85 + 0.15 * sin(u_time * u_churn * 2.5 + fbm(q * 1.1) * TAU);

    // Smooth (2-octave) rivers give LONG continuous seams; the cloudy sharp
    // fractal turbulence is overlaid on top to perturb those seams into jagged,
    // branching cracks (continuity of the rivers + sharpness of the fractal).
    // Sharp, detailed fractal crack network at four rising frequencies — thin
    // jagged cracks, branches, and fine tendrils, with NO big smooth curves.
    float m1 = turbTier(q * 1.5 + 7.0);            // main cracks (semi-connected)
    float m2 = turbTier(q * 3.1 + 27.0);           // secondary branches
    float m3 = turbTier(q * 6.3 + 51.0);           // fine tendrils
    float m4 = turbTier(q * 11.0 + 71.0);          // finest tendrils / sparks
    float ca = 1.0 - smoothstep(0.0, u_crackWidth * 0.85, m1);
    float cb = (1.0 - smoothstep(0.0, u_crackWidth * 0.58, m2)) * 0.9;
    float cc = (1.0 - smoothstep(0.0, u_crackWidth * 0.42, m3)) * 0.78;
    float cd = (1.0 - smoothstep(0.0, u_crackWidth * 0.30, m4)) * 0.6;
    float veins = max(max(ca, cb), max(cc, cd));

    // Thin red glow hugging the main cracks — quick falloff, not big smooth channels.
    float base = 1.0 - smoothstep(0.0, u_crackWidth * 2.0, m1);

    // Heat drives the multi-stop ramp: bright white cores fall off quickly into
    // the deep-red connected base, then cold dark rock.
    float heat = (veins * 1.0 + base * 0.4) * crackVar * shimmer * u_intensity;

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
    // Punch the saturation so the lava reads vivid, not washed.
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = max(mix(vec3(lum), col, 1.35), 0.0);
    // HDR-boost only the very hottest peaked cores so they bloom without blowing
    // the whole surface to white (which is what desaturated it).
    col *= 1.0 + clamp(heat - 0.95, 0.0, 0.9) * 1.2;

    // --- Fiery Fresnel rim — the silhouette glow. u_rimPower sets how far the
    // rim encroaches from the edge (low = wide/deep, high = a thin edge line);
    // u_rimBlend picks how the rim colour combines with the surface. ---
    vec3 V = normalize(cameraPosition - vWorldPos);
    float fres = pow(1.0 - saturate(dot(N, V)), u_rimPower);
    vec2 np = normalize(vLocalPos).xy * 3.0;
    float rflick = 0.75 + 0.25 * vnoise(vec3(np * 2.0, u_time * u_churn * 0.5));
    float rim = fres * rflick;
    // The rim is a Photoshop-style layer: its colour `s` (HDR) composited over
    // the surface `b` through the chosen blend mode at coverage `a` (Fresnel), so
    // the interior (a≈0) is untouched and the mode only acts along the silhouette.
    vec3 b = max(col, 0.0);
    vec3 s = fireGradient(rim * 1.3) * u_rimColor;
    float a = saturate(rim * 0.6);
    vec3 blended;
    if      (u_rimBlend == 1)  blended = b + s;                           // Add (Linear Dodge)
    else if (u_rimBlend == 2)  blended = 1.0 - (1.0 - b) * (1.0 - s);     // Screen
    else if (u_rimBlend == 3)  blended = b * s;                           // Multiply
    else if (u_rimBlend == 4)  blended = overlayBlend(b, s);              // Overlay
    else if (u_rimBlend == 5)  blended = min(b, s);                       // Darken
    else if (u_rimBlend == 6)  blended = max(b, s);                       // Lighten
    else if (u_rimBlend == 7)  blended = b / max(1.0 - s, 1e-4);          // Color Dodge
    else if (u_rimBlend == 8)  blended = 1.0 - (1.0 - b) / max(s, 1e-4);  // Color Burn
    else if (u_rimBlend == 9)  blended = b + s - 1.0;                     // Linear Burn
    else if (u_rimBlend == 10) blended = b + 2.0 * s - 1.0;               // Linear Light
    else if (u_rimBlend == 11) blended = overlayBlend(s, b);             // Hard Light
    else if (u_rimBlend == 12) blended = softLightBlend(b, s);           // Soft Light
    else if (u_rimBlend == 13) blended = vividBlend(b, s);               // Vivid Light
    else if (u_rimBlend == 14) blended = pinBlend(b, s);                 // Pin Light
    else if (u_rimBlend == 15) blended = step(1.0 - s, b);               // Hard Mix
    else if (u_rimBlend == 16) blended = abs(b - s);                     // Difference
    else if (u_rimBlend == 17) blended = b + s - 2.0 * b * s;            // Exclusion
    else if (u_rimBlend == 18) blended = b - s;                          // Subtract
    else if (u_rimBlend == 19) blended = b / max(s, 1e-4);               // Divide
    else                       blended = s;                              // Normal (0)
    col = max(mix(b, blended, a), 0.0);

    // HDR cracks/rim (values >1) pass through to the bloom pass (D21).
    gl_FragColor = vec4(col, 1.0);
}
