import { Color, RawShaderMaterial, Vector2 } from 'three';
import type { ShaderEntry, UniformDef } from '$lib/shaders/types';
import quadVertex from './quadVertex.glsl';
import meshVertex from './meshVertex.glsl';

export function defaultUniformValue(def: UniformDef): number | Color {
	return def.type === 'color' ? new Color(def.default) : def.default;
}

// Standard uniform contract (u_time, u_resolution, u_mouse) + the entry's
// declared uniforms, compiled as raw portable GLSL (D3).
export function createEntryMaterial(entry: ShaderEntry): RawShaderMaterial {
	const uniforms: Record<string, { value: unknown }> = {
		u_time: { value: 0 },
		u_resolution: { value: new Vector2(1, 1) },
		u_mouse: { value: new Vector2(0.5, 0.5) }
	};
	for (const def of entry.meta.uniforms ?? []) {
		uniforms[def.name] = { value: defaultUniformValue(def) };
	}
	return new RawShaderMaterial({
		vertexShader: entry.vertex ?? (entry.meta.harness === 'quad' ? quadVertex : meshVertex),
		fragmentShader: entry.fragment,
		uniforms
	});
}
