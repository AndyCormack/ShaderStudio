<script lang="ts">
	import { Color, type RawShaderMaterial } from 'three';
	import type { ShaderEntry } from '$lib/shaders/types';

	let { entry, material }: { entry: ShaderEntry; material: RawShaderMaterial } = $props();

	const defs = $derived(entry.meta.uniforms ?? []);

	let values = $state<Record<string, number | string>>({});
	let initedFor = '';

	$effect(() => {
		if (entry.slug === initedFor) return;
		initedFor = entry.slug;
		const next: Record<string, number | string> = {};
		for (const d of defs) next[d.name] = d.default;
		values = next;
	});

	// Write-through: push UI values into the live material's uniforms. Runs
	// again when the material is recreated (shader HMR, entry reload), so
	// tweaked values are re-applied rather than lost.
	$effect(() => {
		for (const d of defs) {
			const uniform = material.uniforms[d.name];
			const value = values[d.name];
			if (!uniform || value === undefined) continue;
			if (d.type === 'color') (uniform.value as Color).set(value as string);
			else uniform.value = value;
		}
	});

	function reset() {
		for (const d of defs) values[d.name] = d.default;
	}
</script>

{#if defs.length}
	<aside>
		<header>
			<h2>uniforms</h2>
			<button onclick={reset}>reset</button>
		</header>
		{#each defs as def (def.name)}
			<label>
				<code class="name">{def.name}</code>
				{#if def.type === 'float'}
					<input
						type="range"
						min={def.min}
						max={def.max}
						step={def.step ?? 0.01}
						bind:value={values[def.name]}
					/>
					<span class="value">{Number(values[def.name]).toFixed(2)}</span>
				{:else}
					<input type="color" bind:value={values[def.name]} />
					<span class="value">{values[def.name]}</span>
				{/if}
			</label>
		{/each}
	</aside>
{/if}

<style>
	aside {
		width: 16rem;
		padding: 0.75rem 1rem;
		overflow-y: auto;
		border-left: 1px solid #333;
		background: #1a1a1a;
		color: #ddd;
	}

	header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 0.75rem;
	}

	h2 {
		font-size: 0.9rem;
		margin: 0;
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}

	label {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 0.15rem 0.5rem;
		align-items: center;
		margin-bottom: 0.75rem;
		font-size: 0.85rem;
	}

	.name {
		grid-column: 1 / -1;
	}

	input[type='range'] {
		width: 100%;
	}

	.value {
		font-variant-numeric: tabular-nums;
		color: #999;
	}
</style>
