# Design synthesis — shader-studio

> Derived from [log.md](log.md); if this conflicts with a log entry or ADR, they win — fix this file.

## What it is

shader-studio is a **local-first look-dev sandbox**: a web app you run while working on other projects, for quickly iterating on WebGL shaders destined for games and website effects. The primary destination is **Unreal Engine 5/6** — a shader's exit is a manual translation into UE materials/HLSL, so the studio optimizes for iterating on the *look and algorithm* cheaply, and each shader carries its own UE porting notes ([D1], [D5]).

## Architecture

**Stack:** SvelteKit + Vite + TypeScript ([D2]). Vite's `.glsl` imports + HMR provide the core iteration loop: edit in your IDE, the running studio hot-swaps the compiled shader in ~100ms without losing camera or uniform-slider state ([D6]). There is no in-browser code editor — rejected outright, not deferred ([D6]).

**Styling:** Tailwind v4 (CSS-first via `@tailwindcss/vite`) + shadcn-svelte components with phosphor icons, themed entirely through [DESIGN.md](../../DESIGN.md)'s token values (OKLCH) in `src/app.css`; bespoke components consume the same theme vars, and new shadcn components are added per-need with the non-interactive CLI ([D13]).

**Rendering:** Three.js supplies scene/camera/OrbitControls/primitives, via **Threlte** (`@threlte/core`) as the single rendering path ([D3], [D8]). Authored shaders are standalone portable GLSL compiled with `RawShaderMaterial` (`ShaderMaterial` allowed for injected matrices); Three's lighting/fog/shadow chunks are forbidden in authored shaders — effect shaders carry their own lighting math, which is what keeps them portable ([D3], ADR-0001).

**Harness modes** ([D4], [D8]):

- **Quad** — Shadertoy-style fullscreen fragment shader, for 2D/website effects.
- **Mesh** — shader as material on a switchable primitive, for game-material effects (fireballs, outline glows).
- **Custom scene** — `Scene.svelte` in the shader's folder composes arbitrary Threlte geometry; the harness passes the compiled material in as a prop and the scene attaches it to the meshes it chooses.

All modes share the standard uniform contract (`u_time`, `u_resolution`, `u_mouse`) plus per-shader declared uniforms; quad fragments additionally receive a `varying vec2 vUv` from the harness's default vertex shader.

## Shader entries

One folder per shader under `shaders/`, discovered by Vite glob-import — no registry ([D5]):

```
shaders/fireball/
  fragment.glsl   # required
  vertex.glsl     # optional (default supplied)
  meta.json       # name, tags, harness mode, primitive, uniform declarations
  notes.md        # optional — design intent + UE porting notes
  Scene.svelte    # optional — custom Threlte scene
```

`meta.json`'s uniform declarations (type, range, default) drive an **auto-generated control panel** — sliders and color pickers, live-tweakable, with no per-shader UI code. Controls render at dat.gui-style single-row density on shadcn primitives, headed by a derived uniform label with the raw GLSL name muted beneath it ([D18]).

## Visual system

The MVP design target is **the Electric Workbench**: a canvas-first professional instrument with compact near-black violet-plum chrome and shader output as the primary source of spectacle ([D10], [D11], values corrected to the Preview Atlas mockup by [D15]). Berry Shadow carries broad active fields; Signal Red is reserved for decisive actions, state fills, and dimmed selection edges; Favorite Rose marks only the active favorite star; Hot Coral appears only as a tiny brand-mark spark. System sans typography, restrained 6–12px radii, and tonal layers keep the workspace familiar and focused. Persistent surfaces stay flat; only transient lifted surfaces use subtle, contact-first layered shadows. [PRODUCT.md](../../PRODUCT.md) captures the strategic context and [DESIGN.md](../../DESIGN.md) is normative for visual tokens and component rules.

## Views

- **Gallery** — a Preview Atlas with a persistent discovery rail (Gallery/Favorites/Recent/Tags, count-aware), search-first command band (search, a Filters menu, sort — Recently updated by default), asymmetric live-preview field with one featured shader, a compact selected-shader detail strip (identity, Description, Details, Tags, Usage, Open shader), and a ⌘K command search overlay ([D12], [D14]). Tiles and the strip carry honest metadata only — full fragment path, GLSL version, source size, and updated-ago from build-time folder stats — with ⋯ overflow menus for open/copy/favorite actions ([D19]). Previews render from one shared WebGL context via scissored viewports inside a single Threlte canvas (browsers cap live contexts, so no canvas-per-tile) ([D7]); custom-scene entries preview as their default primitive for now (backlog). Favorites and recents persist in localStorage; Collections and Presets are deferred ([D14]). Click through to:
- **Studio** — the Focus Canvas topology: a full-bleed shader canvas with compact opaque identity, scene, and hideable uniform surfaces lifted at its edges, plus a quiet bottom status strip ([D16]). Reset and collapse are icon-only actions in the uniform-panel heading; collapsed state leaves one show-controls toggle in the Hide action's exact position at 10% resting opacity, fully visible on hover/focus/press. The surrounding panel fades over 150ms with a shorter reduced-motion fade ([D17]). Camera/primitive controls remain directly accessible; below 760px the composition becomes identity, scene controls, canvas, uniform panel, then status. GLSL compile errors will overlay the canvas with line numbers mapped back to the source file.

[D1]: log.md#d1--shader-studio-is-a-local-first-look-dev-sandbox-2026-07-20
[D2]: log.md#d2--stack-sveltekit--vite--typescript-2026-07-20
[D3]: log.md#d3--threejs-as-scene-plumbing-only-shaders-stay-raw-portable-glsl-2026-07-20
[D4]: log.md#d4--two-core-harness-modes-fullscreen-quad--mesh-2026-07-20
[D5]: log.md#d5--folder-per-shader-on-disk-format-with-metajson-2026-07-20
[D6]: log.md#d6--ide-first-editing-in-browser-editor-rejected-outright-2026-07-20
[D7]: log.md#d7--gallery-previews-one-shared-webgl-context-scissored-viewports-2026-07-20
[D12]: log.md#d12--gallery-direction-preview-atlas-2026-07-20
[D8]: log.md#d8--custom-scenes-as-svelte-components-via-threlte-2026-07-20
[D10]: log.md#d10--ui-direction-the-electric-workbench-2026-07-20
[D13]: log.md#d13--styling-stack-tailwind-v4--shadcn-svelte-themed-by-designmd-tokens-2026-07-20
[D14]: log.md#d14--gallery-mvp-state-localstorage-favoritesrecents-collections-and-presets-deferred-2026-07-20
[D15]: log.md#d15--palette-and-tile-anatomy-corrected-to-the-preview-atlas-mockup-2026-07-20
[D16]: log.md#d16--studio-direction-focus-canvas-2026-07-20
[D17]: log.md#d17--uniform-panel-owns-its-collapse-control-2026-07-20
[D18]: log.md#d18--uniform-panel-controls-datgui-density-single-rows-on-shadcn-primitives-derived-labels-2026-07-20
[D19]: log.md#d19--gallery-metadata-reconciled-to-the-preview-atlas-mockup-with-honest-values-2026-07-20
