<script lang="ts">
	import { Canvas } from '@threlte/core';
	import type { RawShaderMaterial } from 'three';
	import type { BloomControls, MeshPrimitive, ShaderEntry } from '$lib/shaders/types';
	import type { SceneComponent } from './scenes';
	import HarnessScene from './HarnessScene.svelte';

	// The material is owned (created + disposed) by the caller, so panels
	// and other consumers can share it.
	let {
		entry,
		material,
		primitive = 'sphere',
		sceneComponent,
		bloom
	}: {
		entry: ShaderEntry;
		material: RawShaderMaterial;
		primitive?: MeshPrimitive;
		sceneComponent?: SceneComponent;
		bloom?: BloomControls;
	} = $props();

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
		<HarnessScene {entry} {material} {primitive} {sceneComponent} {bloom} />
	</Canvas>
</div>

<style>
	.harness {
		width: 100%;
		height: 100%;
	}
</style>
