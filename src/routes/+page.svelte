<script lang="ts">
	import { Canvas } from '@threlte/core';
	import Scene from '$lib/scaffold-smoke/Scene.svelte';
</script>

<main>
	<h1>shader-studio</h1>
	<p>
		Scaffold smoke test: raw GLSL compiled via <code>RawShaderMaterial</code> on a Threlte scene.
		With the dev server running, edit <code>src/lib/scaffold-smoke/fragment.glsl</code> to see HMR.
	</p>
	<div class="viewport">
		<Canvas>
			<Scene />
		</Canvas>
	</div>
</main>

<style>
	main {
		max-width: 60rem;
		margin: 0 auto;
		padding: 1rem;
		font-family: system-ui, sans-serif;
	}

	.viewport {
		width: 100%;
		height: 60vh;
		border-radius: 0.5rem;
		overflow: hidden;
		background: #111;
	}
</style>
