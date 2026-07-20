# PLAN — shader-studio

The live horizon: committed MVP items in dependency order. Finished items roll into [CHANGELOG.md](CHANGELOG.md); deferred scope lives in [backlog.md](backlog.md).

1. **Render harness** — `Next` — quad + mesh modes on Threlte: `RawShaderMaterial`, standard uniform contract, OrbitControls, primitive switcher; custom-scene support (`Scene.svelte` receiving the material as a prop). ([D3], [D4], [D8])
2. **Uniform panel** — `Queued` — auto-generated from `meta.json` (sliders, color pickers), live-tweakable. ([D5], [D6])
3. **Gallery view** — `Queued` — grid of live previews from one shared WebGL context (scissored viewports), click-through to studio view. ([D7])
4. **Compile-error overlay** — `Queued` — GLSL errors on-canvas with line numbers mapped to source files. ([D6])

Deferred scope → [backlog.md](backlog.md).

[D2]: docs/design/log.md
[D3]: docs/design/log.md
[D4]: docs/design/log.md
[D5]: docs/design/log.md
[D6]: docs/design/log.md
[D7]: docs/design/log.md
[D8]: docs/design/log.md
