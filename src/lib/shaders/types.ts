export type HarnessMode = 'quad' | 'mesh';

export type MeshPrimitive = 'sphere' | 'box' | 'torus' | 'torusknot' | 'plane';

export type UniformDef =
	| { name: string; type: 'float'; min: number; max: number; step?: number; default: number }
	| { name: string; type: 'color'; default: string };

/** UnrealBloom parameters for a shader's post-fx pass (D21). */
export interface BloomConfig {
	/** Bloom intensity. */
	strength?: number;
	/** Blur spread, 0–1. */
	radius?: number;
	/** Luminance threshold above which pixels bloom. */
	threshold?: number;
	/** Tint multiplied into the bloom so it glows in-colour, not white (hex). */
	color?: string;
}

/** Concrete, live-tweakable bloom values (meta defaults filled in) (D21). */
export interface BloomControls {
	strength: number;
	radius: number;
	threshold: number;
	color: string;
}

/** Bloom control defaults, shared by the studio panel and preview loop (D21). */
export const BLOOM_DEFAULTS: BloomControls = {
	strength: 0.5,
	radius: 0.4,
	threshold: 0.85,
	color: '#ffffff'
};

/** Merge a shader's declared bloom config over the defaults. */
export function resolveBloom(cfg: BloomConfig | undefined): BloomControls {
	return {
		strength: cfg?.strength ?? BLOOM_DEFAULTS.strength,
		radius: cfg?.radius ?? BLOOM_DEFAULTS.radius,
		threshold: cfg?.threshold ?? BLOOM_DEFAULTS.threshold,
		color: cfg?.color ?? BLOOM_DEFAULTS.color
	};
}

/** Per-shader post-processing stack, applied in the studio only (D21). */
export interface PostFxConfig {
	bloom?: BloomConfig;
}

export interface ShaderMeta {
	name: string;
	tags?: string[];
	harness: HarnessMode;
	/** Mesh harness only; the default primitive the shader is applied to. */
	primitive?: MeshPrimitive;
	/** Optional custom Threlte scene component filename, e.g. "Scene.svelte" (D8). */
	scene?: string;
	/** Optional studio-only post-processing (bloom, …) (D21). */
	postfx?: PostFxConfig;
	uniforms?: UniformDef[];
}

export interface ShaderEntry {
	/** Folder name under shaders/ — the stable identifier. */
	slug: string;
	meta: ShaderMeta;
	fragment: string;
	/** Absent → the harness supplies a default vertex shader. */
	vertex?: string;
	/** Raw notes.md contents when the entry ships one (design intent + porting notes). */
	notes?: string;
	/** GLSL version label derived from the fragment's `#version` directive ("GLSL ES 100" when absent). */
	glslVersion: string;
	/** Total bytes of the entry's GLSL source files. */
	glslBytes: number;
	/** Newest mtime (epoch ms) across the entry's folder; 0 when stats are unavailable. */
	updatedAt: number;
}
