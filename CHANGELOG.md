# Changelog — shader-studio

Notable changes, newest first. What/when only — the *why* lives in the [design log](docs/design/log.md) and [ADRs](docs/adr/).

## 2026-07-20

### Added
- Shader loading (PLAN item 2): glob-built catalog (`src/lib/shaders/catalog.ts`) discovers `shaders/*/` folders, validates `meta.json` (harness mode, `u_`-prefixed uniform defs), and exposes typed entries; the front page lists discovered entries. Seeded with two entries: `plasma` (quad) and `fireball` (mesh, custom vertex shader + UE porting notes). Seed shaders load but don't render yet — that's the render harness, next in PLAN. ([D5])

### Changed
- Package manager: npm → pnpm (pinned via `packageManager`; `pnpm-lock.yaml` replaces `package-lock.json`).

### Added
- App scaffold (PLAN item 1): SvelteKit + Vite + TypeScript (Svelte 5 runes mode), Three.js via Threlte, `vite-plugin-glsl` for `.glsl` imports with HMR. Includes a smoke-test scene (`src/lib/scaffold-smoke/` — raw GLSL on a torus knot via `RawShaderMaterial`); verified with `svelte-check`, a production build, and an SSR page fetch. ([D2], [D3], [D8])
- Project inception: shader-studio, a local-first look-dev sandbox for WebGL shaders destined for games (Unreal Engine 5/6) and website effects. No code yet — design + doc architecture only.

### Docs
- Living-documentation bootstrap: AGENTS.md (conventions + sources-of-truth map), design log with decisions [D1]–[D8], ADR-0001 (Three.js as plumbing, raw GLSL shaders), ADR-0002 (Threlte scene composition), design synthesis, glossary, PLAN, backlog, tech-debt, this changelog.

[D1]: docs/design/log.md
[D2]: docs/design/log.md
[D5]: docs/design/log.md
[D3]: docs/design/log.md
[D8]: docs/design/log.md
