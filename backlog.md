# Backlog — shader-studio

Deferred tickets: recorded, justified, not scheduled. Groomed most-promotable-first. Promote to [PLAN.md](PLAN.md) when committed; roll to [CHANGELOG.md](CHANGELOG.md) when done.

1. **Multi-pass / post-processing support** — `Deferred` — outline-glow-class effects often need a post-process or multi-pass technique (e.g. inverted hull vs. blurred-mask compositing); the MVP harness is single-pass. ([D9](docs/design/log.md))
2. **Custom-scene live previews in gallery tiles** — `Deferred` — gallery tiles for entries with a `Scene.svelte` currently preview the entry's default primitive; rendering the real custom scene needs a way to compose Threlte scene components into the shared scissored-context renderer. ([D7](docs/design/log.md), [D8](docs/design/log.md), [D14](docs/design/log.md))
3. **Collections** — `Deferred` — user-curated groups of shader entries in the discovery rail; needs a data-model decision (where collections live in a local-first tool) before build. ([D14](docs/design/log.md))
4. **Presets** — `Deferred` — saved uniform-value snapshots per shader, surfaced in the rail; needs a persistence decision (sidecar file vs. meta.json vs. localStorage). ([D14](docs/design/log.md))
5. **"Open shaders folder" rail utility** — `Deferred` — opening the OS file browser at `shaders/` requires a local dev-server endpoint; deferred with the other write/exec server surface. ([D14](docs/design/log.md))
6. **Favorites migration to on-disk state** — `Deferred` — favorites/recents live in localStorage (browser-profile-bound); if they should survive profiles/machines, migrate to the folder format via a dev-server write path. ([D14](docs/design/log.md))
7. **Static public showcase build** — `Deferred` — shader-studio is a local-first personal tool first ([D1](docs/design/log.md)); a static gallery deploy is a later milestone, not a day-one constraint.
