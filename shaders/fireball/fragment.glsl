precision highp float;

uniform vec3 cameraPosition; // world-space camera, supplied by three for the mesh
uniform float u_time;
uniform float u_intensity;   // overall heat / HDR push into the highlights
uniform float u_churn;       // brightness shimmer speed (does NOT move the pattern)
uniform float u_scale;       // scale of the fractal crack network
uniform float u_crackWidth;  // seam thickness of the glowing cracks
uniform float u_crust;       // strength/visibility of the rough rock crust
uniform vec3 u_coreColor;    // hot core / gold band of the fire ramp
uniform vec3 u_emberColor;   // deep low-heat ember (the reds of the ramp)
uniform vec3 u_crustColor;   // rough charred rock filling the interiors
uniform vec3 u_rimColor;     // fiery Fresnel rim tint

varying vec3 vLocalPos;
varying vec3 vWorldNormal;
varying vec3 vWorldPos;
varying vec2 vUv;
varying float vCrust;   // burnt-crust height from the vertex displacement

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

// ---------- ridged fractal: sharp creases accumulate into an organic, branching
// crack network — the fractal replacement for the old cellular/Voronoi seams. ----
float ridged(vec3 p) {
    float sum = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < 6; i++) {
        float n = 1.0 - abs(vnoise(p * freq) * 2.0 - 1.0);   // ridge where noise ~ 0.5
        n = n * n;                                            // sharpen the crease
        sum += n * amp;
        freq *= 1.92;
        amp *= 0.55;
    }
    return sum;
}

// Static domain warp (no time) so the pattern is organic but never moves.
vec3 warp(vec3 p) {
    vec3 q = vec3(vnoise(p + vec3(0.0, 1.0, 2.0)),
                  vnoise(p + vec3(5.2, 1.3, 0.8)),
                  vnoise(p + vec3(1.7, 9.2, 3.4)));
    return p + 0.6 * (q - 0.5);
}

// Domain-warped fbm field whose 0.5 contour is the fractal crack network.
float crackField(vec3 pos) {
    float wv = fbm(pos * 0.9 + 2.0);
    return fbm(pos * 1.25 + wv * 2.5 + 7.0);
}

// ---------- HDR fire ramp driven by the ember + core colours. ----------
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

    // STATIC domain — the crack network and crust never move (no time in the
    // coordinates), so the crust doesn't warp. u_churn only shimmers brightness.
    vec3 p = warp(vLocalPos * u_scale);

    // --- Fractal crack network as the thin contour (level-set) of a
    // domain-warped fbm field: genuinely fractal, and thin lines by
    // construction, with dark rock on both sides of each seam. ---
    float field = crackField(p);
    float cd = abs(field - 0.5);

    // Gradient by finite differences (no derivatives extension available), so we
    // can normalise the contour into a uniform thin line instead of broad glowing
    // blobs where the field is shallow.
    float e = 0.08;
    vec3 grad = vec3(crackField(p + vec3(e, 0.0, 0.0)) - field,
                     crackField(p + vec3(0.0, e, 0.0)) - field,
                     crackField(p + vec3(0.0, 0.0, e)) - field);
    float gmag = length(grad) / e + 1e-4;
    float dist = cd / gmag;                               // ~distance to the seam

    // Organic brightness variation so some seams blaze and some fade out.
    float crackVar = 0.4 + 0.85 * fbm(p * 0.6 + 5.0);
    // Gentle heat shimmer — brightness only, so the bands stay put.
    float shimmer = 0.85 + 0.15 * sin(u_time * u_churn * 2.5 + fbm(p * 1.1) * TAU);

    float lw = u_crackWidth * 0.18;
    float crack = (1.0 - smoothstep(0.0, lw, dist)) * crackVar * shimmer;
    float halo = (1.0 - smoothstep(0.0, lw * 3.5, dist)) * crackVar;
    float temp = crack * 1.15 * u_intensity;

    // --- Rough crusty rock/dirt overlay (static) ---
    float rough = ridged(p * 3.0 + 20.0);        // craggy rock ridges
    float grain = fbm(p * 12.0 - 4.0);           // grain
    float fine = vnoise(p * 42.0);               // fine grain
    float speck = vnoise(p * 95.0);              // sharp pits
    float crustTex = rough * 0.5 + grain * 0.35 + fine * 0.15;
    crustTex = smoothstep(0.22, 0.78, crustTex);
    crustTex = mix(crustTex, fine, 0.28);        // break up the smoothness -> rough
    vec3 rock = mix(u_crustColor * 0.12, u_crustColor * 1.2 + vec3(0.02, 0.014, 0.01), crustTex);
    rock *= (0.5 + 0.75 * fine);                 // strong grain shading
    rock = mix(rock, u_crustColor * 0.08, smoothstep(0.5, 0.82, speck) * 0.7);  // dark pits

    // Coverage: rock over the interiors (cr low), lava on the seams (cr high),
    // thicker on the raised displaced plates.
    float coverage = smoothstep(lw * 1.5, lw * 4.0, dist) * (0.55 + 0.8 * smoothstep(0.25, 0.85, vCrust));
    coverage = clamp(coverage * u_crust, 0.0, 1.0);

    // --- Composite: crust over lava; the fractal seams glow through it. ---
    vec3 lava = fireGradient(temp * (1.0 - 0.85 * coverage));
    vec3 col = mix(lava, rock, coverage);
    col += u_coreColor * halo * 0.18 * u_intensity * (1.0 - coverage);   // seam halo, not over rock

    // --- Fiery Fresnel rim — the silhouette ring of fire. ---
    vec3 V = normalize(cameraPosition - vWorldPos);
    float fres = pow(1.0 - saturate(dot(N, V)), 3.2);
    vec2 np = normalize(vLocalPos).xy * 3.0;
    float rflick = 0.75 + 0.25 * vnoise(vec3(np * 2.0, u_time * u_churn * 0.5));
    float rim = fres * rflick;
    col += fireGradient(rim * 1.3) * u_rimColor * rim * (1.4 + crack * 1.4);

    // HDR seams/rim (values >1) pass through to the bloom pass (D21).
    gl_FragColor = vec4(col, 1.0);
}
