<script lang="ts">
	import { Canvas } from '@threlte/core';
	import { WebGLRenderer } from 'three';
	import PreviewRenderLoop from './PreviewRenderLoop.svelte';
	import type { PreviewRegistry } from './preview-registry';

	// One shared WebGL context for every live preview (D7) — the tiles above
	// are transparent windows onto this canvas.
	let { registry }: { registry: PreviewRegistry } = $props();
</script>

<div class="absolute inset-0" aria-hidden="true">
	<Canvas
		autoRender={false}
		createRenderer={(canvas) =>
			new WebGLRenderer({
				canvas,
				antialias: true,
				alpha: true,
				powerPreference: 'high-performance'
			})}
	>
		<PreviewRenderLoop {registry} />
	</Canvas>
</div>
