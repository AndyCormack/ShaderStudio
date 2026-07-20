# shader-studio

> Derived doc: describes the code; on conflict, code wins — fix this file. **Status: MVP in progress** — the gallery (Preview Atlas) and studio views run; the compile-error overlay is not yet built. See [PLAN.md](PLAN.md) for what's next and [CHANGELOG.md](CHANGELOG.md) for history.

A **local-first visual gallery + development studio for WebGL shaders** — a look-dev sandbox for quickly iterating on effects destined for games (Unreal Engine 5/6) and websites. Edit GLSL in your own IDE; the running studio hot-reloads it in place, with live-tweakable uniform controls, a 3D camera, and compile errors overlaid on the canvas.

## Quick start

```sh
pnpm install
pnpm dev --open
```

The front page is the **gallery**: live previews of every entry under `shaders/` rendered from one shared WebGL context, with search (inline + ⌘K overlay), tag/harness filtering, favorites and recents, and a detail strip whose **Open shader** jumps into the studio view (`/shader/<slug>`) — live canvas, orbit camera + geometry switcher for mesh shaders, custom-scene toggle where an entry ships a `Scene.svelte`, and a uniform panel auto-generated from `meta.json` (sliders + color pickers, live). Edit an entry's `.glsl` with the dev server running to see it hot-reload.

## How it works

- **Stack:** SvelteKit + Vite + TypeScript, Three.js via [Threlte](https://threlte.xyz/); UI styled with Tailwind v4 + shadcn-svelte themed by [DESIGN.md](DESIGN.md)'s tokens. Authored shaders are raw, portable GLSL (`RawShaderMaterial`) — no Three-specific material plumbing.
- **A shader is a folder** under `shaders/`: `fragment.glsl`, optional `vertex.glsl`, a `meta.json` declaring uniforms (which auto-generates the control panel), optional `notes.md` with UE porting notes, optional `Scene.svelte` for custom Threlte geometry.
- **Three harness modes:** fullscreen quad (Shadertoy-style), mesh primitive, or a custom scene component that receives the compiled material as a prop.
- **Gallery → studio:** a grid of live previews (one shared WebGL context), click through to the full studio view.

## Repo map

| Path | What |
|---|---|
| [AGENTS.md](AGENTS.md) | How to work here: conventions, sources-of-truth map (canonical; `CLAUDE.md` imports it) |
| [PLAN.md](PLAN.md) / [backlog.md](backlog.md) | Committed next items / deferred tickets |
| [CHANGELOG.md](CHANGELOG.md) | Dated history |
| [CONTEXT.md](CONTEXT.md) | Glossary of canonical terms |
| [docs/design/](docs/design/) | Design log (decisions `Dn`, the *why*) + synthesis (the *now*) |
| [docs/adr/](docs/adr/) | Architectural decision records (promoted from the log) |
| [docs/tech-debt.md](docs/tech-debt.md) | Deferred chores |
| `shaders/` | Shader entries — one folder each |
