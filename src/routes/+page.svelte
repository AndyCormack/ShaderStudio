<script lang="ts">
	import { shaderEntries } from '$lib/shaders/catalog';
</script>

<main>
	<h1>shader-studio</h1>
	<p>Shader entries discovered under <code>shaders/</code> — click through to the studio view.</p>
	<ul>
		{#each shaderEntries as entry (entry.slug)}
			<li>
				<a href="/shader/{entry.slug}"><strong>{entry.meta.name}</strong></a>
				<code>{entry.slug}</code> — {entry.meta.harness} harness{entry.meta.primitive
					? ` (${entry.meta.primitive})`
					: ''}{entry.meta.scene ? ', custom scene' : ''}{entry.vertex
					? ', custom vertex shader'
					: ''}
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

	li {
		margin-bottom: 0.4rem;
	}
</style>
