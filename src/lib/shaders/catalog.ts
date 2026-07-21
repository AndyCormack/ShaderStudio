import shaderStats from 'virtual:shader-stats';
import type { ShaderEntry, ShaderMeta } from './types';

// The catalog is derived at build time from the shaders/ tree — adding a shader
// is adding a folder; there is no hand-maintained registry (D5).
const metaModules = import.meta.glob('/shaders/*/meta.json', { eager: true, import: 'default' });
const fragmentModules = import.meta.glob('/shaders/*/fragment.glsl', {
	eager: true,
	import: 'default'
});
const vertexModules = import.meta.glob('/shaders/*/vertex.glsl', { eager: true, import: 'default' });
const notesModules = import.meta.glob('/shaders/*/notes.md', {
	eager: true,
	query: '?raw',
	import: 'default'
});
// Keys only — custom scene components are lazy-loaded by the harness (D8).
const scenePaths = new Set(Object.keys(import.meta.glob('/shaders/*/Scene.svelte')));

function slugOf(path: string): string {
	return path.split('/')[2];
}

// Raw portable GLSL without a `#version` directive compiles as GLSL ES 1.00
// under WebGL (D3), so that's the honest default label.
function glslVersionOf(fragment: string): string {
	const match = fragment.match(/^\s*#version\s+(\d+)(\s+es)?/m);
	if (!match) return 'GLSL ES 100';
	return match[2] ? `GLSL ES ${match[1]}` : `GLSL ${match[1]}`;
}

function validateMeta(slug: string, raw: unknown): ShaderMeta {
	const meta = raw as ShaderMeta;
	if (typeof meta?.name !== 'string' || meta.name === '') {
		throw new Error(`shaders/${slug}/meta.json: "name" must be a non-empty string`);
	}
	if (meta.harness !== 'quad' && meta.harness !== 'mesh') {
		throw new Error(`shaders/${slug}/meta.json: "harness" must be "quad" or "mesh"`);
	}
	if (meta.scene !== undefined && meta.scene !== 'Scene.svelte') {
		throw new Error(`shaders/${slug}/meta.json: "scene" must be "Scene.svelte" when present`);
	}
	const hasSceneFile = scenePaths.has(`/shaders/${slug}/Scene.svelte`);
	if (meta.scene && !hasSceneFile) {
		throw new Error(`shaders/${slug}/meta.json declares "scene" but Scene.svelte is missing`);
	}
	if (!meta.scene && hasSceneFile) {
		throw new Error(`shaders/${slug}/ has a Scene.svelte not declared in meta.json ("scene")`);
	}
	if (meta.postfx !== undefined) {
		const bloom = meta.postfx.bloom;
		if (bloom) {
			for (const key of ['strength', 'radius', 'threshold'] as const) {
				const v = bloom[key];
				if (v !== undefined && (typeof v !== 'number' || !isFinite(v))) {
					throw new Error(`shaders/${slug}/meta.json: postfx.bloom.${key} must be a number`);
				}
			}
		}
	}
	for (const u of meta.uniforms ?? []) {
		const { name, type } = u as { name?: unknown; type?: unknown };
		if (typeof name !== 'string' || !name.startsWith('u_')) {
			throw new Error(`shaders/${slug}/meta.json: uniform names must start with "u_"`);
		}
		if (type !== 'float' && type !== 'color') {
			throw new Error(`shaders/${slug}/meta.json: uniform "${name}" has unknown type`);
		}
	}
	return meta;
}

function buildCatalog(): ShaderEntry[] {
	const entries: ShaderEntry[] = [];
	for (const [path, rawMeta] of Object.entries(metaModules)) {
		const slug = slugOf(path);
		const fragment = fragmentModules[`/shaders/${slug}/fragment.glsl`];
		if (typeof fragment !== 'string') {
			throw new Error(`shaders/${slug}/ has a meta.json but no fragment.glsl`);
		}
		const vertex = vertexModules[`/shaders/${slug}/vertex.glsl`];
		const notes = notesModules[`/shaders/${slug}/notes.md`];
		const stats = shaderStats[slug];
		entries.push({
			slug,
			meta: validateMeta(slug, rawMeta),
			fragment,
			vertex: typeof vertex === 'string' ? vertex : undefined,
			notes: typeof notes === 'string' ? notes : undefined,
			glslVersion: glslVersionOf(fragment),
			glslBytes: stats?.glslBytes ?? 0,
			updatedAt: stats?.updatedAt ?? 0
		});
	}
	for (const path of Object.keys(fragmentModules)) {
		const slug = slugOf(path);
		if (!metaModules[`/shaders/${slug}/meta.json`]) {
			throw new Error(`shaders/${slug}/ has a fragment.glsl but no meta.json`);
		}
	}
	return entries.sort((a, b) => a.meta.name.localeCompare(b.meta.name));
}

export const shaderEntries: ShaderEntry[] = buildCatalog();

export function getEntry(slug: string): ShaderEntry | undefined {
	return shaderEntries.find((e) => e.slug === slug);
}
