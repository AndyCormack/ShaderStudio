# Shader Studio

![Shader Studio — Local-first GLSL look-dev](docs/design/mockups/readme-banner.png)

A local-first gallery and dev studio for WebGL shaders. It's a sandbox to iterate on effects before they end up in a game (Unreal Engine 5/6) or on a website.

You edit GLSL in your own editor; the running app hot-reloads it in place, with sliders for the uniforms and an orbitable camera. Compile errors don't show up on the canvas yet — that's the next thing on [PLAN.md](PLAN.md).

Still an MVP. [PLAN.md](PLAN.md) has what's next, [CHANGELOG.md](CHANGELOG.md) has what's happened.

## Quick start

```sh
pnpm install
pnpm dev --open
```

## Using it

The front page is the gallery: a live preview of every entry under `shaders/`, all drawn from one shared WebGL context. You can search (inline or ⌘K), filter by tag or harness, and mark favorites; recently opened shaders float up too. Clicking a tile opens a detail strip, and "Open shader" takes you into the studio.

The studio (`/shader/<slug>`) is where you actually work on a shader:

- Save the `.glsl` file in your editor and the canvas updates in place.
- The uniform panel is generated from the entry's `meta.json` — sliders and color pickers that update the shader as you drag.
- Orbit camera and a geometry switcher, for mesh shaders.
- If the entry ships its own `Scene.svelte`, there's a toggle to render that custom scene instead.

## Adding a shader

Make a folder under `shaders/` and it shows up in the gallery. There's no registry or config to touch anywhere else.

```
shaders/my-effect/
├── fragment.glsl    # required
├── vertex.glsl      # optional
├── meta.json        # declares uniforms → auto-generates the control panel
├── notes.md         # optional — e.g. UE porting notes
└── Scene.svelte     # optional — custom Threlte geometry
```

An entry renders in one of three harness modes: a fullscreen quad (Shadertoy-style), a mesh primitive, or a custom scene component that receives the compiled material as a prop.

## Under the hood

- SvelteKit + Vite + TypeScript, with Three.js through [Threlte](https://threlte.xyz/).
- Tailwind v4 and shadcn-svelte for the UI, themed by the tokens in [DESIGN.md](DESIGN.md).
- Shaders are plain, portable GLSL (`RawShaderMaterial`) — no Three-specific material plumbing, so effects port cleanly to other engines.

## Repo map

| Path                                          | What                                                                                    |
| --------------------------------------------- | --------------------------------------------------------------------------------------- |
| [AGENTS.md](AGENTS.md)                        | How to work here: conventions, sources-of-truth map (canonical; `CLAUDE.md` imports it) |
| [PLAN.md](PLAN.md) / [backlog.md](backlog.md) | Committed next items / deferred tickets                                                 |
| [CHANGELOG.md](CHANGELOG.md)                  | Dated history                                                                           |
| [CONTEXT.md](CONTEXT.md)                      | Glossary of canonical terms                                                             |
| [docs/design/](docs/design/)                  | Design log (decisions `Dn`, the _why_) + synthesis (the _now_)                          |
| [docs/adr/](docs/adr/)                        | Architectural decision records (promoted from the log)                                  |
| [docs/tech-debt.md](docs/tech-debt.md)        | Deferred chores                                                                         |
| `shaders/`                                    | Shader entries — one folder each                                                        |

---

_Derived doc: this file describes the code; on conflict, code wins — fix this file._
