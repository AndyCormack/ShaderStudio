# Fireball — notes

A magma sphere built in layers. A **fractal crack network** — the thin contour (level-set) of a domain-warped value-noise fbm field, its width normalised by the field gradient (computed with finite differences, since the `GL_OES_standard_derivatives` extension isn't available on this ES-1.00-on-WebGL2 context) so the seams stay uniformly thin — glows between a **rough charred-rock crust** (ridged noise + grain + sharp pits) that fills the interiors. A blackbody palette keeps most of the surface dark rock and pushes only the crack lines to orange→core→white-hot; a world-space Fresnel term rings the silhouette with fire. Hot seams and rim are emitted as HDR (>1) so the studio **bloom** pass ([D21]) gives them their glow.

The pattern's **structure is static** — no per-feature warping — but the whole texture (cracks + crust + the vertex displacement) **scrolls up the Y axis** at `u_scroll`: a uniform translation of the sample domain, so cracks, crust, and relief all move together rather than distorting. `u_churn` only drives a gentle brightness shimmer.

## Uniforms

- `u_intensity` — overall brightness / HDR push into the highlights.
- `u_churn` — brightness shimmer speed (does not move the pattern).
- `u_scroll` — speed the whole texture scrolls up the Y axis (0 = still).
- `u_scale` — scale of the fractal crack network.
- `u_crackWidth` — thickness of the glowing seams.
- `u_displace` — amplitude of the (static) rock displacement.
- `u_crust` — how much of the surface the rough crust reclaims.
- `u_coreColor` — hot core / gold band of the fire ramp.
- `u_emberColor` — deep low-heat ember (the reds of the ramp).
- `u_crustColor` — rough charred rock filling the interiors.
- `u_rimColor` — fiery Fresnel rim tint.

Post-fx (in `meta.json`, live-tweakable in the studio Post-FX panel): a bloom pass with a colour tint so the glow stays in-colour rather than washing to white; strength scales with render resolution so previews match the full render.

## UE porting notes

- Fractal cracks → threshold a domain-warped noise field near a level and normalise the line width by its screen-space derivative (`ddx`/`ddy`), or bake the crack mask to a tiling texture.
- Rough crust → ridged/turbulence noise + high-frequency grain into base-colour darkening; feed a height into **World Position Offset** (or displacement) for the uneven surface.
- Fire ramp → a Curve Atlas / gradient lerp driven by the crack heat scalar into Emissive; keep it HDR for Bloom.
- Fresnel rim → the built-in `Fresnel` node into Emissive, multiplied by the crack mask for the edge flare.
- Bloom → post-process Bloom (the studio's post-fx maps straight across). Real *flying* embers → a Niagara ember emitter around the mesh.
