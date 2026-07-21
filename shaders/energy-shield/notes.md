# Energy Shield — notes

Forked as an exact duplicate of the **Fireball** shader to diverge from (same cellular-lava sphere, controls, and bloom); retune the colours/uniforms toward a shield look.

A magma sphere built in layers. An animated 3D Worley network paints glowing cracks between cooler cells, domain-warped by value-noise fbm so the crust reads as molten rather than geometric. A **burnt, crispy charred-rock crust** (fbm plates + grit speckle) fills the cell interiors with warm lava breathing through the low crevices, so it reads as hot lava rather than veins-on-black. The vertex shader adds a subtle **displacement map** (the same crust fbm along the normal) so the surface is physically uneven. A blackbody palette keeps most of the surface dark ember and pushes only the crack lines to orange→core→white-hot, and a world-space Fresnel term rings the silhouette with fire. The hottest seams and rim are emitted as HDR values (>1) so the studio **bloom** pass ([D21]) gives them their glow and the ember halo that bleeds onto the plum background.

## Uniforms

- `u_intensity` — overall brightness / HDR push into the highlights.
- `u_churn` — speed of the molten surface churn (also drifts the displacement).
- `u_scale` — cell density of the lava network (maps directly to Worley density).
- `u_crackWidth` — thickness of the glowing veins.
- `u_displace` — amplitude of the burnt-crust vertex displacement.
- `u_crust` — strength/visibility of the burnt rock crust.
- `u_coreColor` — hot core / gold band of the fire ramp.
- `u_emberColor` — deep low-heat ember (the reds of the ramp).
- `u_crustColor` — charred rock filling the cell interiors.
- `u_rimColor` — fiery Fresnel rim tint.

Post-fx (in `meta.json`, live-tweakable in the studio Post-FX panel): a bloom pass with a colour tint so the glow stays in-colour rather than washing to white; strength scales with render resolution so previews match the full render.

## UE porting notes

- Worley cracks → a Voronoi node (or baked Worley texture) feeding a thin-line mask via `F2 - F1`; cheaper to sample a tiling 3D noise texture than to evaluate analytic Worley in a UE material.
- Burnt crust → a tiling fbm/noise into base-colour darkening + the same height into **World Position Offset** (or a tessellation/displacement material) for the uneven surface.
- Fire ramp → a Curve Atlas / gradient lerp driven by the crack heat scalar into Emissive; keep it HDR for Bloom.
- Fresnel rim → the built-in `Fresnel` node into Emissive, multiplied by the crack mask for the edge flare.
- Bloom → post-process Bloom (the studio's post-fx maps straight across). Real *flying* embers → a Niagara ember emitter around the mesh, rather than faking it in-shader.
