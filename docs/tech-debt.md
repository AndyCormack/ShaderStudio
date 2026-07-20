# Tech debt — shader-studio

Deferred chores: pure "we should tidy X" notes with no decision behind them. Anything with a *why* belongs in [backlog.md](../backlog.md) instead.

- Shader HMR currently recreates the material/scene, so camera position and (future) uniform-slider state reset on `.glsl` edits. Investigate state-preserving hot-swap (patch `fragmentShader`/`vertexShader` + `needsUpdate` on the live material instead of recreating).
