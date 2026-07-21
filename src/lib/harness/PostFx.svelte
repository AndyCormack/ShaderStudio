<script lang="ts">
	import { onDestroy } from 'svelte';
	import { useThrelte, useTask } from '@threlte/core';
	import { Vector2, type Camera } from 'three';
	import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
	import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
	import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
	import type { BloomControls } from '$lib/shaders/types';
	import { applyBloom } from './bloom';

	// A studio post-processing stack driven by live bloom controls (D21).
	// Replaces Threlte's auto-render with a manual EffectComposer render on the
	// render stage, per Threlte's postprocessing guidance.
	let { bloom }: { bloom: BloomControls } = $props();

	const { renderer, scene, camera, size, renderStage, autoRender } = useThrelte();

	const composer = new EffectComposer(renderer);
	const bloomPass = new UnrealBloomPass(new Vector2(1, 1), 0.7, 0.6, 0.55);
	const outputPass = new OutputPass();
	let renderPass: RenderPass | undefined;

	// Build the pipeline once a camera exists; retarget the render pass if it changes.
	$effect(() => {
		const cam = camera.current as Camera | undefined;
		if (!cam) return;
		if (!renderPass) {
			renderPass = new RenderPass(scene, cam);
			composer.addPass(renderPass);
			composer.addPass(bloomPass);
			composer.addPass(outputPass);
		} else {
			renderPass.camera = cam;
		}
	});

	$effect(() => {
		composer.setSize(size.current.width, size.current.height);
	});

	// Live bloom controls → the pass (resolution-scaled strength + colour tint).
	$effect(() => {
		applyBloom(bloomPass, bloom, size.current.height * renderer.getPixelRatio());
	});

	// Take over rendering while mounted; hand it back on unmount.
	$effect(() => {
		const before = autoRender.current;
		autoRender.set(false);
		return () => autoRender.set(before);
	});

	useTask(
		(delta) => {
			if (renderPass) composer.render(delta);
		},
		{ stage: renderStage, autoInvalidate: false }
	);

	onDestroy(() => {
		composer.dispose();
		bloomPass.dispose();
	});
</script>
