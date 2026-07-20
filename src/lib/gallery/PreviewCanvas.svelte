<script lang="ts">
	import { Canvas } from '@threlte/core';
	import { WebGLRenderer } from 'three';
	import PreviewRenderLoop from './PreviewRenderLoop.svelte';
	import type { PreviewRegistry } from './preview-registry';

	// One shared WebGL context for every live preview (D7) — registered
	// viewports (atlas tiles, the detail-strip thumb) are transparent
	// windows onto this canvas.
	let { registry }: { registry: PreviewRegistry } = $props();
</script>

<!--
	z-20: scissored previews must paint above surface backgrounds (the detail
	strip's bg would otherwise cover its thumb window); interactive overlays
	(dialogs z-50) stay above, and per-tile masks/stars sit at z-30.
-->
<div class="pointer-events-none absolute inset-0 z-20" aria-hidden="true">
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
