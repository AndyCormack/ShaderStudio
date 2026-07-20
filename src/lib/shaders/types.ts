export type HarnessMode = 'quad' | 'mesh';

export type MeshPrimitive = 'sphere' | 'box' | 'torus' | 'torusknot' | 'plane';

export type UniformDef =
	| { name: string; type: 'float'; min: number; max: number; step?: number; default: number }
	| { name: string; type: 'color'; default: string };

export interface ShaderMeta {
	name: string;
	tags?: string[];
	harness: HarnessMode;
	/** Mesh harness only; the default primitive the shader is applied to. */
	primitive?: MeshPrimitive;
	/** Optional custom Threlte scene component filename, e.g. "Scene.svelte" (D8). */
	scene?: string;
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
}
