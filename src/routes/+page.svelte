<script lang="ts">
	import { Canvas } from '@threlte/core';
	import Scene from '$lib/scaffold-smoke/Scene.svelte';
	import { shaderEntries } from '$lib/shaders/catalog';
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

	<h2>Catalog</h2>
	<p>Shader entries discovered under <code>shaders/</code> (rendering lands with the harness):</p>
	<ul>
		{#each shaderEntries as entry (entry.slug)}
			<li>
				<strong>{entry.meta.name}</strong>
				<code>{entry.slug}</code> — {entry.meta.harness} harness{entry.meta.primitive
					? ` (${entry.meta.primitive})`
					: ''},
				{entry.meta.uniforms?.length ?? 0} uniforms{entry.vertex ? ', custom vertex shader' : ''}
				{#if entry.meta.tags?.length}
					<em>[{entry.meta.tags.join(', ')}]</em>
				{/if}
			</li>
		{/each}
	</ul>
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
