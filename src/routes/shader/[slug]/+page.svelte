<script lang="ts">
	import type { MeshPrimitive } from '$lib/shaders/types';
	import { loadCustomScene, type SceneComponent } from '$lib/harness/scenes';
	import { createEntryMaterial } from '$lib/harness/material';
	import { recordRecent } from '$lib/gallery/gallery-state.svelte';
	import Harness from '$lib/harness/Harness.svelte';
	import UniformPanel from '$lib/harness/UniformPanel.svelte';

	let { data } = $props();
	const entry = $derived(data.entry);

	// Direct navigations count as visits too, so the gallery's Recent section
	// stays truthful (D14).
	$effect(() => {
		recordRecent(entry.slug);
	});

	// Recreated when the entry changes (including shader HMR updates).
	const material = $derived(createEntryMaterial(entry));

	$effect(() => {
		const m = material;
		return () => m.dispose();
	});

	const primitives: MeshPrimitive[] = ['sphere', 'box', 'torus', 'torusknot', 'plane'];
	let primitive = $state<MeshPrimitive>('sphere');
	let useCustomScene = $state(true);
	let sceneComponent = $state<SceneComponent | undefined>();

	$effect(() => {
		primitive = entry.meta.primitive ?? 'sphere';
		useCustomScene = Boolean(entry.meta.scene);
	});

	$effect(() => {
		if (entry.meta.scene && useCustomScene) {
			let stale = false;
			loadCustomScene(entry.slug).then((c) => {
				if (!stale) sceneComponent = c;
			});
			return () => {
				stale = true;
			};
		}
		sceneComponent = undefined;
	});
</script>

<svelte:head>
	<title>{entry.meta.name} — shader-studio</title>
</svelte:head>

<main>
	<header>
		<a href="/">← gallery</a>
		<h1>{entry.meta.name}</h1>
		<code>shaders/{entry.slug}/</code>
		{#if entry.meta.harness === 'mesh'}
			<label>
				geometry
				<select bind:value={primitive} disabled={useCustomScene && Boolean(entry.meta.scene)}>
					{#each primitives as p (p)}
						<option value={p}>{p}</option>
					{/each}
				</select>
			</label>
			{#if entry.meta.scene}
				<label>
					<input type="checkbox" bind:checked={useCustomScene} />
					custom scene
				</label>
			{/if}
		{/if}
	</header>

	<div class="content">
		<div class="viewport">
			<Harness {entry} {material} {primitive} {sceneComponent} />
		</div>
		<UniformPanel {entry} {material} />
	</div>
</main>

<style>
	main {
		display: flex;
		flex-direction: column;
		height: 100vh;
		font-family: system-ui, sans-serif;
	}

	header {
		display: flex;
		align-items: center;
		gap: 1rem;
		padding: 0.5rem 1rem;
	}

	header h1 {
		font-size: 1.2rem;
		margin: 0;
	}

	.content {
		display: flex;
		flex: 1;
		min-height: 0;
	}

	.viewport {
		flex: 1;
		min-width: 0;
		background: #111;
	}
</style>
