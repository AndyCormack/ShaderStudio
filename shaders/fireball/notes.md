# Fireball — notes

A magma sphere built from a single **multi-stop heat ramp**. Three layered tiers of domain-warped **turbulence** (sums of abs-value-noise — the "fractal clouds") at rising density define the lava — bold primary rivers, medium branches, fine tendrils — joined by a wider connected base so the veins read as rivers rather than isolated spots. The `heat` scalar (varied by a large-scale temperature field so whole regions run hotter or cooler) runs the surface through a rich many-stop ramp — cold rough rock (`u_crustColor`) → near-black red → deep red → glowing red → orange → amber → gold core (`u_coreColor`) → white-hot. A rough rock texture (ridged noise + grain + sharp pits) shades the cold end, and a world-space Fresnel term rings the silhouette. Hot cores and rim are emitted as HDR (>1) so the studio **bloom** pass ([D21]) gives them their glow.

The pattern's **structure is static** — no per-feature boiling — but the whole texture (the turbulence cloud + crust + the vertex displacement) **scrolls up the Y axis** at `u_scroll`: a rigid translation of the sample domain, so everything moves together as one molten sheet rather than distorting. `u_churn` only drives a gentle brightness shimmer.

## Uniforms

- `u_intensity` — overall heat / HDR push into the highlights.
- `u_churn` — brightness shimmer speed (does not move the pattern).
- `u_scroll` — speed the whole texture scrolls up the Y axis (0 = still).
- `u_scale` — scale of the turbulence cloud (lava density).
- `u_crackWidth` — how wide the glowing lava reads out of each turbulence dip.
- `u_displace` — amplitude of the rock displacement.
- `u_crust` — strength of the rough rock texture on the cold end of the ramp.
- `u_coreColor` — gold core stop of the ramp.
- `u_emberColor` — deep-red ember-glow stop of the ramp.
- `u_crustColor` — cold rough rock (the cold end of the ramp).
- `u_rimColor` — fiery Fresnel rim tint.

Post-fx (in `meta.json`, live-tweakable in the studio Post-FX panel): a bloom pass with a colour tint so the glow stays in-colour rather than washing to white; strength scales with render resolution so previews match the full render.

## UE porting notes

- Lava cloud → domain-warped **turbulence** (`Σ abs(noise)`) sampled in a scrolled object-space domain; threshold near its minima for the molten regions.
- Multi-stop ramp → a Curve Atlas / gradient lerp driven by the `heat` scalar (rock → ember → orange → core → white) into Emissive; keep it HDR for Bloom.
- Rough crust → ridged/turbulence noise + high-frequency grain into base colour; feed a height into **World Position Offset** (or displacement) for the uneven surface.
- Fresnel rim → the built-in `Fresnel` node into Emissive.
- Bloom → post-process Bloom (the studio's post-fx maps straight across). Real *flying* embers → a Niagara ember emitter around the mesh.
