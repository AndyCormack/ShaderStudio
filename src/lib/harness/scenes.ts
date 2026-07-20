import type { Component } from 'svelte';
import type { RawShaderMaterial } from 'three';

export type SceneComponent = Component<{ material: RawShaderMaterial }>;

const sceneModules = import.meta.glob('/shaders/*/Scene.svelte');

export function hasCustomScene(slug: string): boolean {
	return `/shaders/${slug}/Scene.svelte` in sceneModules;
}

export async function loadCustomScene(slug: string): Promise<SceneComponent | undefined> {
	const loader = sceneModules[`/shaders/${slug}/Scene.svelte`];
	if (!loader) return undefined;
	const mod = (await loader()) as { default: SceneComponent };
	return mod.default;
}
