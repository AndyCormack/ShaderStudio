# Design log — shader-studio

Append-mostly record of decisions: numbered, dated, with rejected alternatives. This is the *why*; the readable current-state view is [synthesis.md](synthesis.md). Decision IDs (`Dn`) are the referencing currency across all docs.

---

## D1 — shader-studio is a local-first look-dev sandbox (2026-07-20)

A local-first web app for quickly iterating on and developing shaders destined for *other* projects — games and website effects. The primary destination is **Unreal Engine 5/6**, so a shader's exit path is a **manual translation** into UE materials/HLSL: the studio's value is iterating on the look and the algorithm cheaply, not producing paste-ready engine code.

**Rejected:** a hosted public showcase as a day-one constraint — no backend/persistence story needed for a personal iteration tool. A static public build remains a deferred ticket in [backlog.md](../../backlog.md).

## D2 — Stack: SvelteKit + Vite + TypeScript (2026-07-20)

SvelteKit + Vite + TypeScript for the app shell. Vite provides `.glsl` file imports with hot-reload for free, which *is* the quick-iteration loop the project exists for.

**Rejected:** no alternatives seriously considered — this matches the user's established Svelte 5 tooling.

## D3 — Three.js as scene plumbing only; shaders stay raw portable GLSL (2026-07-20)

Three.js is adopted for scene/camera/OrbitControls/primitives — but authored shaders are standalone `.glsl` files compiled via **`RawShaderMaterial`** (nothing injected), with `ShaderMaterial` allowed where the auto-injected matrices (`projectionMatrix`, `modelViewMatrix`, `position`, `normal`, `uv`) save boilerplate. Authored shaders must **not** use Three's built-in lighting/fog/shadow chunks (`#include <…>`): effect shaders (fireballs, outline glows, dissolves) carry their own lighting math, which is what keeps the algorithm portable to UE (per [D1]).

**Rejected:** raw WebGL2 with no Three.js — loses easy camera control and scene composition. Three's full material system with chunk includes — bakes Three-specific plumbing into shaders, killing portability.

**Promoted:** [ADR-0001](../adr/ADR-0001-three-as-plumbing-raw-glsl.md).

## D4 — Two core harness modes: fullscreen quad + mesh (2026-07-20)

Both are core, not one-primary-one-later: a Shadertoy-style fullscreen-quad mode for pure 2D/website effects, and a mesh mode for material-style effects on 3D geometry (fireball materials, character outline glows), with a standard uniform contract (`u_time`, `u_resolution`, `u_mouse`) plus per-shader declared uniforms.

**Rejected:** quad-only MVP — the stated targets (UE mesh materials) make the mesh harness core.

## D5 — Folder-per-shader on-disk format with `meta.json` (2026-07-20)

A shader entry is one self-describing folder under `shaders/`:

```
shaders/fireball/
  fragment.glsl   # required
  vertex.glsl     # optional — harness supplies a default if absent
  meta.json       # name, tags, harness (quad | mesh), mesh primitive,
                  # uniform definitions → auto-generated UI controls
  notes.md        # optional — design intent + UE porting notes
  Scene.svelte    # optional — custom Threlte scene (see D8)
```

The load-bearing piece: `meta.json` declares uniforms with type + range + default, so the studio auto-builds sliders/color-pickers with no per-shader UI code. Entries are discovered by Vite glob-import — adding a shader = adding a folder, no registration step. `notes.md` is where per-shader UE porting notes live (per [D1]).

**Rejected:** a single central registry file — one more place to touch per shader, merge-conflict bait. Uniform declarations as GLSL comment annotations — single-file appeal, but needs a bespoke parser.

## D6 — IDE-first editing; in-browser editor rejected outright (2026-07-20)

GLSL is edited in the user's own IDE; Vite HMR hot-swaps the compiled shader in the running studio without losing camera or uniform-slider state. The studio's jobs: render, overlay compile errors (line numbers mapped to the source file), and expose auto-generated uniform controls + camera + mesh switcher. An in-browser code editor is **rejected, not deferred** — it duplicates existing tooling and adds portability the workflow doesn't need. Exposed, live-tweakable parameters (the uniform panel) are core in its place.

**Rejected:** Shadertoy-style in-browser Monaco/CodeMirror editor (explicitly not wanted, not even as a backlog ticket).

## D7 — Gallery previews: one shared WebGL context, scissored viewports (2026-07-20)

The gallery grid renders live previews from a **single shared WebGL context** drawing each tile via scissored viewports, not a canvas-per-tile.

**Rejected:** canvas per tile — browsers cap live WebGL contexts (~8–16), so a gallery of any size silently kills contexts. Static thumbnail images — loses the "live" gallery feel and adds a capture pipeline.

## D8 — Custom scenes as Svelte components via Threlte (2026-07-20)

Custom per-shader scenes are Svelte components composed of Three.js elements using **Threlte** (`@threlte/core`, v8 / Svelte 5): `shaders/<name>/Scene.svelte` builds arbitrary geometry declaratively (`<T.Mesh>`, `<T.TorusKnotGeometry>`, …). The harness passes the compiled shader material in as a prop, and the scene attaches it to whichever meshes it chooses — that is the material-targeting mechanism. `meta.json` gains an optional `"scene"` field; absent → default primitive scene. The built-in quad/primitive harnesses also run on Threlte so there is one rendering path.

**Rejected:** plain TypeScript scene modules (`createScene(three) => { root, targets }`) — no new dependency, but imperative per-scene setup code, hand-rolled lifecycle/reactivity glue, and not the Svelte-component authoring that was asked for.

**Promoted:** [ADR-0002](../adr/ADR-0002-threlte-scene-composition.md).

## D9 — Multi-pass / post-processing deferred from MVP (2026-07-20)

The MVP harness is single-pass. Outline-glow-class effects (a stated target) typically need a post-process or multi-pass technique — inverted hull, blurred-mask compositing, etc. — so multi-pass support is confirmed as wanted, but deferred: it rides in [backlog.md](../../backlog.md) until the single-pass MVP proves the iteration loop.

**Rejected:** designing multi-pass into the MVP harness now — speculative complexity ahead of a working single-pass loop.

## D10 — UI direction: the Electric Workbench (2026-07-20)

The product UI is a **canvas-first professional instrument with an electric edge**. Shader output carries the spectacle while compact carbon-plum chrome recedes around it. **Pulse Magenta** is the interaction color; **Signal Cyan** is reserved for the mark and rare signature moments. The system uses familiar system sans typography, refined radii with a 12px ceiling, flat tonal layering for persistent structure, and subtle multi-layer shadows only when transient surfaces genuinely lift. Gallery discovery — live previews, search, tags, and filtering — is a core interaction concern as the collection grows. [PRODUCT.md](../../PRODUCT.md) captures the strategy; [DESIGN.md](../../DESIGN.md) owns the normative visual tokens and rules.

**Rejected:** Rive's neutral visual language as the complete identity — approachable but insufficiently distinctive. Also rejected: a dense Blender/Unity cockpit, generic SaaS dashboard styling, RGB-gamer cyberpunk, bubbly creative-tool geometry, acid citron as the signature color, and decorative effects that compete with shader output. ComfyUI Desktop remains the main personality reference, combined with Rive's approachability, PlayCanvas's workspace structure, and Shadertoy's discovery model.

## D11 — Mulberry and restrained signal palette (2026-07-20)

The Electric Workbench uses **Mulberry Canvas `#2D132C`** as its foundation, with same-hue surface steps for persistent depth. **Deep Berry `#801336`** carries broad active-state structure and routine statuses; **Signal Red `#C72C41`** is reserved for decisive actions and restrained focus edges; **Hot Coral `#EE4540`** is limited to a tiny brand-mark spark. Slider tracks, checkbox fills, input borders, view toggles, selected rows, card selection, and similar operational chrome stay Deep Berry or restrained Signal Red so active states do not compete with shader output. Slider thumbs never use a white ring or glow. [DESIGN.md](../../DESIGN.md) owns the exact derived surface and text tokens.

**Rejected:** the earlier Pulse Magenta / Signal Cyan pairing, a navy/teal foundation, teal or deep-aubergine signature colors, and bright-red structural chrome. These directions either felt generic creative-tech, under-contrasted, or too loud across routine controls.

## D12 — Gallery direction: Preview Atlas (2026-07-20)

The Gallery uses a **Preview Atlas**: a persistent discovery rail and search-first command band frame an asymmetric live-preview field, with one large featured shader, supporting medium and small previews, and a compact selected-shader detail strip across the bottom. This balances rapid visual scanning with enough metadata to rediscover shaders as the collection grows. The Gallery remains a discovery and launch surface; detailed tuning belongs to the Studio.

**Rejected:** a uniform catalog grid as the primary composition, a selected-preview shelf that reduces whole-library scanability, and a command-results list as the default view. Those structures remain useful secondary modes or interaction patterns but do not provide the chosen balance of visual identity, comparison, and scalable discovery.
