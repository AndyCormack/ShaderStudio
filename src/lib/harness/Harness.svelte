<script lang="ts">
	import { Canvas } from '@threlte/core';
	import type { MeshPrimitive, ShaderEntry } from '$lib/shaders/types';
	import type { SceneComponent } from './scenes';
	import { createEntryMaterial } from './material';
	import HarnessScene from './HarnessScene.svelte';

	let {
		entry,
		primitive = 'sphere',
		sceneComponent
	}: {
		entry: ShaderEntry;
		primitive?: MeshPrimitive;
		sceneComponent?: SceneComponent;
	} = $props();

	// Recreated when the entry changes (including shader HMR updates).
	const material = $derived(createEntryMaterial(entry));

	$effect(() => {
		const m = material;
		return () => m.dispose();
	});

	function onpointermove(event: PointerEvent) {
		const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
		material.uniforms.u_mouse.value.set(
			(event.clientX - rect.left) / rect.width,
			1 - (event.clientY - rect.top) / rect.height
		);
	}
</script>

<div class="harness" role="presentation" {onpointermove}>
	<Canvas>
		<HarnessScene {entry} {material} {primitive} {sceneComponent} />
	</Canvas>
</div>

<style>
	.harness {
		width: 100%;
		height: 100%;
	}
</style>
