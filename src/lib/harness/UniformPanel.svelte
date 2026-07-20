<script lang="ts">
	import ArrowCounterClockwise from 'phosphor-svelte/lib/ArrowCounterClockwise';
	import SlidersHorizontal from 'phosphor-svelte/lib/SlidersHorizontal';
	import { Color, type RawShaderMaterial } from 'three';
	import type { ShaderEntry } from '$lib/shaders/types';

	let { entry, material }: { entry: ShaderEntry; material: RawShaderMaterial } = $props();

	const defs = $derived(entry.meta.uniforms ?? []);
	let values = $state<Record<string, number | string>>({});
	let initedFor = '';

	$effect(() => {
		if (entry.slug === initedFor) return;
		initedFor = entry.slug;
		values = {};
	});

	// Write-through: push UI values into the live material's uniforms. Runs
	// again when the material is recreated (shader HMR, entry reload), so
	// tweaked values are re-applied rather than lost.
	$effect(() => {
		for (const definition of defs) {
			const uniform = material.uniforms[definition.name];
			const value = values[definition.name] ?? definition.default;
			if (!uniform) continue;
			if (definition.type === 'color') (uniform.value as Color).set(value as string);
			else uniform.value = value;
		}
	});

	function reset() {
		values = {};
	}

	function currentValue(definition: (typeof defs)[number]): number | string {
		return values[definition.name] ?? definition.default;
	}

	function displayValue(definition: (typeof defs)[number]): string {
		const value = currentValue(definition);
		return definition.type === 'float' ? Number(value).toFixed(2) : String(value);
	}

	function setValue(name: string, event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		values[name] = input.type === 'range' ? Number(input.value) : input.value;
	}
</script>

<aside class="uniform-panel" aria-label="Uniform panel">
	<header>
		<h2>Uniforms</h2>
		<button type="button" class="reset-button" onclick={reset} disabled={defs.length === 0}>
			<ArrowCounterClockwise size={15} />
			<span>Reset</span>
		</button>
	</header>

	{#if defs.length}
		<div class="controls">
			{#each defs as definition (definition.name)}
				<label class="uniform-control">
					<span class="control-heading">
						<code>{definition.name}</code>
						<output for={`uniform-${definition.name}`}>
							{displayValue(definition)}
						</output>
					</span>
					{#if definition.type === 'float'}
						<input
							id={`uniform-${definition.name}`}
							type="range"
							min={definition.min}
							max={definition.max}
							step={definition.step ?? 0.01}
							value={currentValue(definition)}
							oninput={(event) => setValue(definition.name, event)}
						/>
						<span class="range-ends" aria-hidden="true">
							<span>{definition.min}</span>
							<span>{definition.max}</span>
						</span>
					{:else}
						<span class="color-field">
							<input
								id={`uniform-${definition.name}`}
								type="color"
								value={currentValue(definition)}
								oninput={(event) => setValue(definition.name, event)}
							/>
							<span class="swatch-value">{currentValue(definition)}</span>
						</span>
					{/if}
				</label>
			{/each}
		</div>
	{:else}
		<div class="empty-state">
			<SlidersHorizontal size={18} />
			<p>This shader has no authored uniforms.</p>
		</div>
	{/if}
</aside>

<style>
	.uniform-panel {
		display: flex;
		height: 100%;
		min-height: 0;
		flex-direction: column;
		background: var(--surface);
		color: var(--foreground);
	}

	header {
		display: flex;
		min-height: 3.25rem;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		border-bottom: 1px solid var(--border);
		padding: 0.625rem 0.75rem;
	}

	h2 {
		margin: 0;
		font-size: 0.875rem;
		font-weight: 650;
		line-height: 1.2;
	}

	.reset-button {
		display: inline-flex;
		height: 2rem;
		align-items: center;
		gap: 0.375rem;
		border-radius: 6px;
		padding: 0 0.625rem;
		color: var(--muted-foreground);
		font-size: 0.75rem;
		font-weight: 550;
		transition:
			background 180ms var(--ease-workbench),
			color 180ms var(--ease-workbench);
	}

	.reset-button:hover:not(:disabled) {
		background: var(--surface-raised);
		color: var(--foreground);
	}

	.reset-button:focus-visible,
	input:focus-visible {
		outline: 2px solid var(--ring);
		outline-offset: 2px;
	}

	.reset-button:disabled {
		cursor: not-allowed;
		color: var(--ink-subtle);
	}

	.controls {
		display: flex;
		min-height: 0;
		flex: 1;
		flex-direction: column;
		gap: 0.375rem;
		overflow: auto;
		padding: 0.75rem;
	}

	.uniform-control {
		display: flex;
		flex-direction: column;
		gap: 0.625rem;
		border-radius: 8px;
		background: color-mix(in oklch, var(--surface-raised) 60%, var(--surface));
		padding: 0.75rem;
	}

	.control-heading,
	.range-ends,
	.color-field {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
	}

	code,
	output,
	.swatch-value,
	.range-ends {
		font-family: var(--font-mono);
		font-variant-numeric: tabular-nums;
	}

	code {
		font-size: 0.75rem;
		font-weight: 550;
	}

	output {
		color: var(--muted-foreground);
		font-size: 0.6875rem;
	}

	input[type='range'] {
		width: 100%;
		height: 0.875rem;
		cursor: pointer;
		accent-color: var(--primary);
	}

	.range-ends {
		margin-top: -0.375rem;
		color: var(--ink-subtle);
		font-size: 0.625rem;
	}

	.color-field {
		justify-content: flex-start;
		border: 1px solid var(--border);
		border-radius: 6px;
		background: var(--background);
		padding: 0.375rem 0.5rem;
	}

	input[type='color'] {
		width: 1.75rem;
		height: 1.75rem;
		cursor: pointer;
		border: 0;
		border-radius: 4px;
		background: transparent;
		padding: 0;
	}

	.swatch-value {
		color: var(--muted-foreground);
		font-size: 0.6875rem;
	}

	.empty-state {
		display: flex;
		min-height: 8rem;
		flex: 1;
		align-items: center;
		justify-content: center;
		gap: 0.625rem;
		padding: 1.5rem;
		color: var(--muted-foreground);
		font-size: 0.8125rem;
		text-align: center;
	}

	.empty-state p {
		max-width: 22ch;
	}

	@media (prefers-reduced-motion: reduce) {
		.reset-button {
			transition: none;
		}
	}
</style>
