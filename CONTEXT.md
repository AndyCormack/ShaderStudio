# CONTEXT.md — glossary

Canonical terms for shader-studio. One term per concept; alternatives listed under _Avoid_. Authoritative for terminology per [AGENTS.md](AGENTS.md).

**shader entry** — one folder under `shaders/` holding a complete, self-describing shader: GLSL source, `meta.json`, and optional notes/custom scene. The unit the gallery lists and the studio opens. _Avoid: sketch, demo, example._

**harness** — the rendering wrapper that compiles a shader entry and runs it in a scene. Comes in three modes: quad, mesh, custom scene.

**quad harness** — Shadertoy-style mode: the fragment shader drawn on a fullscreen quad, for 2D/website effects.

**mesh harness** — the shader applied as a material to a switchable 3D primitive, for game-material effects.

**custom scene** — a `Scene.svelte` in a shader entry's folder: a Threlte component composing arbitrary geometry, which receives the compiled material as a prop and attaches it to the meshes it chooses.

**catalog** — the runtime index of shader entries, derived by glob-importing `shaders/*/` at build time. Not a hand-maintained registry — adding a shader is adding a folder. _Avoid: registry._

**uniform contract** — the standard uniforms every harness supplies (`u_time`, `u_resolution`, `u_mouse`) plus the entry's own uniforms declared in `meta.json`.

**uniform panel** — the auto-generated live controls (sliders, color pickers) built from `meta.json`'s uniform declarations. _Avoid: inspector, tweakpane._

**gallery** — the grid view of live shader-entry previews, rendered from one shared WebGL context.

**preview atlas** — the gallery's composition: one featured live preview, supporting medium and small tiles on a shared 12-column grid, framed by the discovery rail, command band, and detail strip. _Avoid: dashboard, mosaic view._

**discovery rail** — the gallery's persistent left navigation: Gallery, Favorites, Recent, and Tags, each count-aware. _Avoid: sidebar (in gallery context)._

**command band** — the gallery's top bar: inline search first, harness filter chips and sort subordinate. _Avoid: toolbar, header._

**detail strip** — the compact selected-shader panel spanning the gallery's bottom edge: metadata, tags, favorite toggle, and the single **Open shader** action. _Avoid: inspector (that's the studio's uniform panel territory)._

**command search** — the ⌘K overlay listing shaders, tags, and views with keyboard-first navigation; selecting a shader opens it in the studio. _Avoid: command palette, quick switcher._

**studio** — the full-size single-entry view: canvas, camera, uniform panel, compile-error overlay.

**look-dev sandbox** — the project's role: a cheap place to iterate on a shader's look and algorithm before manually translating it to its destination engine.

**porting notes** — a shader entry's `notes.md`: design intent plus how the effect would be rebuilt in Unreal Engine.
