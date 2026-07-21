# Lava Lamp — notes

Sum-of-sines wobble displaces a sphere along its normals; displacement doubles as a heat value driving an ember→core color ramp with a time flicker. Deliberately cheap seed shader — no real noise yet. (Renamed from the original "Fireball" seed — the new Fireball entry is the cellular-lava sphere.)

## UE porting notes

- Displacement → World Position Offset in a UE material: same sum-of-sines on `Time`/local position, scaled by an `Intensity` scalar parameter.
- Heat ramp → lerp between two Vector parameters driven by the same wobble value; flicker via `Time`-driven sine into emissive.
- For a production version, replace sum-of-sines with a noise texture sample (cheaper and better-looking than analytic noise in UE).
