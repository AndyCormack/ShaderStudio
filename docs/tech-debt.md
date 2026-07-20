# Tech debt — shader-studio

Deferred chores: pure "we should tidy X" notes with no decision behind them. Anything with a *why* belongs in [backlog.md](../backlog.md) instead.

- Shader HMR recreates the material, so camera position may reset on `.glsl` edits (uniform-slider state now survives via the panel's write-through re-apply — verify camera behavior in browser). Investigate state-preserving hot-swap (patch `fragmentShader`/`vertexShader` + `needsUpdate` on the live material instead of recreating).
