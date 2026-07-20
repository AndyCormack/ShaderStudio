# Changelog — shader-studio

Notable changes, newest first. What/when only — the *why* lives in the [design log](docs/design/log.md) and [ADRs](docs/adr/).

## 2026-07-20

### Changed
- Gallery visuals reconciled with the Preview Atlas mockup ([D15]): palette darkened to near-black violet-plum (sampled from the mockup) with Berry Shadow active fields, deepened Signal Red, and a new Favorite Rose star state; tiles rebuilt as bordered cards (preview on top; title + harness badge, mono path, tag chips, and meta row below); favoriting is an always-visible top-left star; the rail gained the brand mark, an Electric Workbench subtitle, and harness filters (moved out of the command band); the detail strip gained a preview thumbnail (a frozen frame seeded from the live tile at selection), a Description column read from each entry's `notes.md`, and a key-value Details column. DESIGN.md token values and component rules updated to match.

### Fixed
- Live previews rendered offset/scaled away from their tiles on displays with a device pixel ratio other than 1 (e.g. Windows display scaling): the scissored render loop pre-multiplied viewport/scissor rects by the pixel ratio, which Three.js also does internally. Coordinates are now passed in CSS pixels; only `u_resolution` uses device pixels.
- Preview corners bled past the tile's rounded border at fractional pixel ratios: sub-pixel rects get floored/scaled inside Three, letting the scissored render land 1px proud of its container. Rects are now rounded to whole CSS pixels and inset by 1px, so the draw region can never escape the card; verified pixel-level at DPR 1.25 and 1.5.

### Added
- Gallery view (PLAN item 5): the Preview Atlas at `/` — discovery rail (Gallery/Favorites/Recent/Tags with counts), search-first command band (inline search, harness filter chips, sort), asymmetric live-preview grid (featured + medium + small tiles), selected-shader detail strip with **Open shader**, and a ⌘K Command Search overlay grouping shaders/tags/views. Live previews render from one shared WebGL context via scissored viewports inside a single Threlte `<Canvas>` (`src/lib/gallery/`); custom-scene entries preview as their default primitive (full scene in the studio). Favorites/recents persist in localStorage; keyboard: arrows select, Enter opens, `/` focuses search, Ctrl/⌘K opens the palette. Replaces the placeholder entry list on the front page. ([D7], [D12], [D14])
- Styling stack: Tailwind v4 (`@tailwindcss/vite`, CSS-first — no `tailwind.config.*`) + shadcn-svelte (nova style, neutral base, phosphor icons, CLI as devDep for non-interactive adds), with `src/app.css` overriding the scaffolded token values with DESIGN.md's Electric Workbench palette in OKLCH plus workbench-specific tokens (`surface-raised`, `selected`, `signature`, `viewport`, radii, contact-first shadows). Installed components: button, input, badge, separator, tooltip, select, command, dialog (+ CLI-pulled input-group/textarea). ([D13])
- Uniform panel (PLAN item 4): studio sidebar auto-generated from `meta.json` uniform declarations — range sliders for floats (min/max/step), color pickers for colors, live write-through into the running material's uniforms, per-entry reset. Values are re-applied when the material is recreated, so tweaks survive shader HMR. Material ownership moved from `Harness` to the studio page so panel and canvas share it. ([D5], [D6])
- Render harness + studio route (PLAN item 3): `src/lib/harness/` renders entries via `RawShaderMaterial` with the standard uniform contract (`u_time`, `u_resolution`, `u_mouse` from pointer tracking). Quad mode draws a fullscreen quad (default vertex shader supplies `vUv`); mesh mode adds PerspectiveCamera + OrbitControls + a 5-primitive geometry switcher; custom scenes (`Scene.svelte`, lazy-loaded, material passed as prop) render arbitrary Threlte geometry — demonstrated by fireball's core-plus-orbiting-embers scene. Studio view at `/shader/[slug]` (404 on unknown slugs); catalog validates `meta.json` `"scene"` against `Scene.svelte` presence. ([D3], [D4], [D8])

### Removed
- Scaffold smoke test (`src/lib/scaffold-smoke/`) — superseded by the render harness; the front page now links entries to their studio views.

### Added
- Shader loading (PLAN item 2): glob-built catalog (`src/lib/shaders/catalog.ts`) discovers `shaders/*/` folders, validates `meta.json` (harness mode, `u_`-prefixed uniform defs), and exposes typed entries; the front page lists discovered entries. Seeded with two entries: `plasma` (quad) and `fireball` (mesh, custom vertex shader + UE porting notes). Seed shaders load but don't render yet — that's the render harness, next in PLAN. ([D5])

### Fixed
- Custom scenes failed to lazy-load in dev (403/404 — `shaders/` is outside Vite's default file-serving allow list); `server.fs.allow` now includes it. Production builds were unaffected.

### Changed
- Gallery design direction: Preview Atlas composition with a featured live preview, supporting mosaic, persistent discovery rail, search-first command band, and compact selected-shader detail strip. ([D12])
- Electric Workbench palette: mulberry surface scale with restrained Deep Berry, Signal Red, and Hot Coral roles; active control chrome no longer uses bright accent fills broadly. ([D11])
- Package manager: npm → pnpm (pinned via `packageManager`; `pnpm-lock.yaml` replaces `package-lock.json`).

### Added
- App scaffold (PLAN item 1): SvelteKit + Vite + TypeScript (Svelte 5 runes mode), Three.js via Threlte, `vite-plugin-glsl` for `.glsl` imports with HMR. Includes a smoke-test scene (`src/lib/scaffold-smoke/` — raw GLSL on a torus knot via `RawShaderMaterial`); verified with `svelte-check`, a production build, and an SSR page fetch. ([D2], [D3], [D8])
- Project inception: shader-studio, a local-first look-dev sandbox for WebGL shaders destined for games (Unreal Engine 5/6) and website effects. No code yet — design + doc architecture only.

### Docs
- Product and visual design context: `PRODUCT.md`, the Electric Workbench token/component system in `DESIGN.md`, its Impeccable live-panel sidecar, and preconfigured SvelteKit live mode. ([D10])
- Living-documentation bootstrap: AGENTS.md (conventions + sources-of-truth map), design log with decisions [D1]–[D8], ADR-0001 (Three.js as plumbing, raw GLSL shaders), ADR-0002 (Threlte scene composition), design synthesis, glossary, PLAN, backlog, tech-debt, this changelog.

[D1]: docs/design/log.md
[D2]: docs/design/log.md
[D5]: docs/design/log.md
[D3]: docs/design/log.md
[D8]: docs/design/log.md
[D10]: docs/design/log.md
[D11]: docs/design/log.md
[D12]: docs/design/log.md
[D7]: docs/design/log.md
[D13]: docs/design/log.md
[D14]: docs/design/log.md
[D15]: docs/design/log.md
