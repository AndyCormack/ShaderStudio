# AGENTS.md — how to work on shader-studio

**Status: active build — MVP.** Nothing is implemented yet; the doc architecture and design decisions exist, the code does not. Build from `PLAN.md`, top item first.

## Start here

1. This file — the sources-of-truth map and conventions.
2. [PLAN.md](PLAN.md) — what to build next.
3. [docs/design/synthesis.md](docs/design/synthesis.md) — the whole design as it stands.
4. [CONTEXT.md](CONTEXT.md) — canonical terms; use them.

## Sources of truth

| Topic | Source of truth | Authority |
|---|---|---|
| Decisions + rationale (the *why*) | [docs/design/log.md](docs/design/log.md) (IDs `Dn`) + [docs/adr/](docs/adr/) | **binds** |
| Current design (the *now*) | [docs/design/synthesis.md](docs/design/synthesis.md) | binds (derived from log; log wins) |
| Terminology | [CONTEXT.md](CONTEXT.md) | **binds** |
| Committed near-future work | [PLAN.md](PLAN.md) | binds |
| Deferred tickets | [backlog.md](backlog.md) | informs |
| Deferred chores (no decision behind them) | [docs/tech-debt.md](docs/tech-debt.md) | informs |
| History — what changed, when | [CHANGELOG.md](CHANGELOG.md) | binds (append-only) |
| Outward surface + repo map | [README.md](README.md) | informs (derived; code wins) |

**Precedence on conflict:** recorded decisions (log/ADRs) > synthesis > README/backlog/anything derived. `CONTEXT.md` is authoritative for terminology. On *any* contradiction — doc-vs-doc, doc-vs-code, request-vs-recorded-decision — **stop and raise it**; never silently pick a side. Fix the losing doc as part of the resolution.

## Conventions (ratified)

- **Decision IDs:** `Dn — title (YYYY-MM-DD)`, sequential, minted in the design log the moment a decision lands. All docs reference decisions by ID. ADRs are *promotions* of log entries that pass all three tests (hard to reverse · surprising without context · real trade-off); the full rationale stays in the log, the ADR is a terse pointer, linked both ways. ADR files: `docs/adr/ADR-NNNN-slug.md`.
- **Docs are living, same-commit:** the doc changes a code change necessitates ship in the **same commit**. Code ahead of docs, docs ahead of code, and stale point-in-time text are all drift — fix on sight or raise.
- **CHANGELOG:** Keep-a-Changelog style, newest first, entries dated `YYYY-MM-DD`, grouped Added/Changed/Fixed/Removed/Docs. What/when only — the *why* is a `Dn` link. Skip routine chores.
- **PLAN/backlog/tech-debt split:** PLAN holds the next ~3–6 committed items only (statuses: `In progress` / `Next` / `Decision needed`); deferred *tickets* (they have a why + decision link) go to `backlog.md`, kept groomed with most-promotable on top; undecided cleanups go to `docs/tech-debt.md`.
- **Glossary:** add coined/project terms to `CONTEXT.md` the moment they're minted; one canonical term, rest under _Avoid_; no implementation detail.
- **Maturity honesty:** mark MVP/first-draft work as such, with known limits — "it exists" ≠ "it's done".
- **De-volatilize:** no drift-prone counts/"currently" language in this file or other durable docs; status lives in PLAN/CHANGELOG. (The phase marker at the top of this file is the one allowed exception — update it only on phase changes.)

## Project-specific rules

- **Authored shaders are raw portable GLSL** — no Three.js lighting/fog/shadow chunk includes, ever ([D3](docs/design/log.md), [ADR-0001](docs/adr/ADR-0001-three-as-plumbing-raw-glsl.md)). Effect shaders carry their own lighting math.
- **One rendering path: Threlte** ([D8](docs/design/log.md), [ADR-0002](docs/adr/ADR-0002-threlte-scene-composition.md)).
- **Adding a shader = adding a folder** under `shaders/` — never introduce a central registry ([D5](docs/design/log.md)).
- **No in-browser code editor** — rejected, not deferred ([D6](docs/design/log.md)). Don't re-propose it.
