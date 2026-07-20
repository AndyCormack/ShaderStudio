<script lang="ts">
	import Cube from 'phosphor-svelte/lib/Cube';
	import FrameCorners from 'phosphor-svelte/lib/FrameCorners';
	import Hexagon from 'phosphor-svelte/lib/Hexagon';
	import SlidersHorizontalIcon from 'phosphor-svelte/lib/SlidersHorizontalIcon';
	import { quintOut } from 'svelte/easing';
	import { fade } from 'svelte/transition';
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
	let panelOpen = $state(true);
	let prefersReducedMotion = $state(false);

	const panelFade = $derived(
		prefersReducedMotion
			? { duration: 80, easing: quintOut }
			: { duration: 150, easing: quintOut }
	);

	const activeSceneLabel = $derived(
		entry.meta.harness === 'quad'
			? 'Fullscreen quad'
			: useCustomScene && entry.meta.scene
				? 'Custom scene'
				: primitive === 'torusknot'
					? 'Torus knot'
					: primitive.charAt(0).toUpperCase() + primitive.slice(1)
	);

	$effect(() => {
		primitive = entry.meta.primitive ?? 'sphere';
		useCustomScene = Boolean(entry.meta.scene);
	});

	$effect(() => {
		const media = window.matchMedia('(prefers-reduced-motion: reduce)');
		const updatePreference = () => (prefersReducedMotion = media.matches);
		updatePreference();
		media.addEventListener('change', updatePreference);
		return () => media.removeEventListener('change', updatePreference);
	});

	$effect(() => {
		if (entry.meta.scene && useCustomScene) {
			let stale = false;
			loadCustomScene(entry.slug).then((component) => {
				if (!stale) sceneComponent = component;
			});
			return () => {
				stale = true;
			};
		}
		sceneComponent = undefined;
	});

	function choosePrimitive(next: MeshPrimitive) {
		primitive = next;
		useCustomScene = false;
	}
</script>

<svelte:head>
	<title>{entry.meta.name} — shader-studio</title>
</svelte:head>

<main class:panel-hidden={!panelOpen} class="studio">
	<header class="identity-bar">
		<a href="/" class="gallery-link" aria-label="Back to gallery">
			<span aria-hidden="true">←</span>
			<span>Gallery</span>
		</a>

		<div class="shader-identity">
			<span class="brand-mark"><Hexagon size={24} weight="duotone" /></span>
			<div>
				<div class="title-line">
					<h1>{entry.meta.name}</h1>
					<span class="harness-badge">{entry.meta.harness}</span>
				</div>
				<code>shaders/{entry.slug}/</code>
			</div>
		</div>
	</header>

	<section class="scene-controls" aria-label="Scene controls">
		<div class="scene-heading">
			<span class="scene-icon">
				{#if entry.meta.harness === 'mesh'}
					<Cube size={16} weight="duotone" />
				{:else}
					<FrameCorners size={16} />
				{/if}
			</span>
			<span>
				<strong>Scene</strong>
				<small>{activeSceneLabel}</small>
			</span>
		</div>

		{#if entry.meta.harness === 'mesh'}
			<div class="scene-options" role="group" aria-label="Choose scene geometry">
				{#if entry.meta.scene}
					<button
						type="button"
						class:active={useCustomScene}
						aria-pressed={useCustomScene}
						onclick={() => (useCustomScene = true)}
					>
						Custom
					</button>
				{/if}
				{#each primitives as candidate (candidate)}
					<button
						type="button"
						class:active={!useCustomScene && primitive === candidate}
						aria-pressed={!useCustomScene && primitive === candidate}
						onclick={() => choosePrimitive(candidate)}
					>
						{candidate === 'torusknot' ? 'Knot' : candidate}
					</button>
				{/each}
			</div>
		{:else}
			<span class="quad-note">Canvas-filling output</span>
		{/if}
	</section>

	<section class="viewport-shell" aria-label={`${entry.meta.name} live preview`}>
		<div class="viewport">
			<Harness {entry} {material} {primitive} {sceneComponent} />
		</div>
		<div class="viewport-label">
			<span class="viewport-dot"></span>
			<span>{activeSceneLabel}</span>
		</div>
		{#if entry.meta.harness === 'mesh'}
			<p class="viewport-hint">Drag to orbit · scroll to zoom</p>
		{/if}
	</section>

	{#if panelOpen}
		<div id="uniform-panel-region" class="uniform-region" transition:fade={panelFade}>
			<UniformPanel {entry} {material} onhide={() => (panelOpen = false)} />
		</div>
	{:else}
		<button
			type="button"
			class="panel-reveal"
			aria-label="Show controls"
			aria-controls="uniform-panel-region"
			aria-expanded="false"
			title="Show controls"
			onclick={() => (panelOpen = true)}
		>
			<SlidersHorizontalIcon size={16} />
		</button>
	{/if}

	<footer class="status-strip">
		<span class="render-status"><span></span>Live preview</span>
		<span>{activeSceneLabel}</span>
		<code>{entry.meta.uniforms?.length ?? 0} uniforms</code>
		<code class="status-path">shaders/{entry.slug}/fragment.glsl</code>
	</footer>
</main>

<style>
	.studio {
		--z-chrome: 10;
		position: relative;
		display: grid;
		height: 100svh;
		grid-template-areas:
			'canvas'
			'status';
		grid-template-rows: minmax(0, 1fr) 1.75rem;
		overflow: hidden;
		background: var(--background);
		color: var(--foreground);
	}

	.identity-bar,
	.scene-controls,
	.uniform-region {
		position: absolute;
		z-index: var(--z-chrome);
		border-radius: 10px;
		box-shadow: var(--shadow-lifted);
	}

	.identity-bar {
		top: 0.75rem;
		left: 0.75rem;
		display: flex;
		height: 3.5rem;
		max-width: min(32rem, calc(50% - 1.125rem));
		align-items: center;
		gap: 0.875rem;
		background: var(--surface);
		padding: 0 0.75rem;
	}

	.gallery-link {
		display: inline-flex;
		height: 2.125rem;
		flex: 0 0 auto;
		align-items: center;
		gap: 0.4375rem;
		border-radius: 6px;
		color: var(--muted-foreground);
		font-size: 0.75rem;
		font-weight: 550;
		text-decoration: none;
		transition:
			background 180ms var(--ease-workbench),
			color 180ms var(--ease-workbench);
	}

	.gallery-link {
		padding: 0 0.625rem;
	}

	.gallery-link:hover {
		background: var(--surface-raised);
		color: var(--foreground);
	}

	.gallery-link:focus-visible,
	.panel-reveal:focus-visible,
	.scene-options button:focus-visible {
		outline: 2px solid var(--ring);
		outline-offset: 2px;
	}

	.shader-identity {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 0.625rem;
	}

	.brand-mark {
		display: grid;
		flex: 0 0 auto;
		place-items: center;
		color: var(--signature);
	}

	.shader-identity > div {
		min-width: 0;
	}

	.title-line {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 0.5rem;
	}

	h1 {
		margin: 0;
		overflow: hidden;
		font-size: 0.9375rem;
		font-weight: 650;
		letter-spacing: -0.01em;
		line-height: 1.2;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.shader-identity code,
	.status-strip code {
		color: var(--muted-foreground);
		font-family: var(--font-mono);
		font-size: 0.6875rem;
	}

	.harness-badge {
		border: 1px solid var(--border);
		border-radius: 5px;
		padding: 0.125rem 0.375rem;
		color: var(--muted-foreground);
		font-size: 0.625rem;
		font-weight: 550;
		text-transform: capitalize;
	}

	.scene-controls {
		top: 0.75rem;
		right: 0.75rem;
		display: flex;
		height: 3.5rem;
		max-width: min(40rem, calc(50% - 1.125rem));
		align-items: center;
		gap: 0.75rem;
		background: var(--surface);
		padding: 0.625rem 0.75rem;
	}

	.scene-heading {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 0.5rem;
	}

	.scene-icon {
		display: grid;
		width: 1.875rem;
		height: 1.875rem;
		flex: 0 0 auto;
		place-items: center;
		border-radius: 6px;
		background: var(--surface-raised);
	}

	.scene-heading > span:last-child {
		display: flex;
		min-width: 0;
		flex-direction: column;
	}

	.scene-heading strong {
		font-size: 0.75rem;
		font-weight: 650;
	}

	.scene-heading small,
	.quad-note {
		color: var(--muted-foreground);
		font-size: 0.625rem;
		white-space: nowrap;
	}

	.scene-options {
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 0.1875rem;
		overflow-x: auto;
		scrollbar-width: none;
	}

	.scene-options::-webkit-scrollbar {
		display: none;
	}

	.scene-options button {
		height: 1.875rem;
		flex: 0 0 auto;
		border-radius: 5px;
		padding: 0 0.5rem;
		color: var(--muted-foreground);
		font-size: 0.6875rem;
		font-weight: 550;
		text-transform: capitalize;
		transition:
			background 180ms var(--ease-workbench),
			color 180ms var(--ease-workbench);
	}

	.scene-options button:hover {
		background: var(--surface-raised);
		color: var(--foreground);
	}

	.scene-options button.active {
		background: var(--selected);
		color: var(--foreground);
		box-shadow: inset 0 0 0 1px color-mix(in oklch, var(--primary) 62%, transparent);
	}

	.viewport-shell {
		position: relative;
		grid-area: canvas;
		min-width: 0;
		min-height: 0;
		overflow: hidden;
		background: var(--viewport);
	}

	.viewport {
		position: absolute;
		inset: 0;
	}

	.viewport-label,
	.viewport-hint {
		position: absolute;
		z-index: 2;
		bottom: 0.75rem;
		border-radius: 6px;
		background: color-mix(in oklch, var(--background) 92%, transparent);
		color: var(--muted-foreground);
		font-size: 0.6875rem;
		font-weight: 550;
		pointer-events: none;
	}

	.viewport-label {
		left: 0.75rem;
		display: flex;
		align-items: center;
		gap: 0.4375rem;
		padding: 0.4375rem 0.625rem;
	}

	.viewport-dot {
		width: 0.375rem;
		height: 0.375rem;
		border-radius: 999px;
		background: var(--foreground);
		opacity: 0.75;
	}

	.viewport-hint {
		right: 19.5rem;
		margin: 0;
		padding: 0.4375rem 0.625rem;
		transition: right 180ms var(--ease-workbench);
	}

	.panel-hidden .viewport-hint {
		right: 0.75rem;
	}

	.uniform-region {
		top: 5rem;
		right: 0.75rem;
		bottom: 2.5rem;
		width: 18rem;
		overflow: hidden;
	}

	.panel-reveal {
		position: absolute;
		top: 5.625rem;
		right: 1.5rem;
		z-index: var(--z-chrome);
		display: grid;
		width: 2rem;
		height: 2rem;
		place-items: center;
		border-radius: 6px;
		background: var(--surface);
		box-shadow: var(--shadow-lifted);
		color: var(--muted-foreground);
		opacity: 0.5;
		transition:
			opacity 180ms var(--ease-workbench),
			background 180ms var(--ease-workbench),
			color 180ms var(--ease-workbench);
	}

	.panel-reveal:hover,
	.panel-reveal:focus-visible,
	.panel-reveal:active {
		background: var(--surface-raised);
		color: var(--foreground);
		opacity: 1;
	}

	.status-strip {
		grid-area: status;
		display: flex;
		min-width: 0;
		align-items: center;
		gap: 1rem;
		border-top: 1px solid var(--border);
		background: var(--background);
		padding: 0 0.75rem;
		color: var(--muted-foreground);
		font-size: 0.6875rem;
	}

	.render-status {
		display: inline-flex;
		align-items: center;
		gap: 0.375rem;
		color: var(--foreground);
		font-weight: 550;
	}

	.render-status > span {
		width: 0.375rem;
		height: 0.375rem;
		border-radius: 999px;
		background: var(--foreground);
	}

	.status-path {
		margin-left: auto;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	@media (max-width: 960px) and (min-width: 761px) {
		.identity-bar {
			right: 0.75rem;
			max-width: none;
		}

		.scene-controls {
			top: 5rem;
			left: 0.75rem;
			right: 19.5rem;
			max-width: none;
		}

		.panel-hidden .scene-controls {
			right: 0.75rem;
		}
	}

	@media (max-width: 760px) {
		.studio,
		.studio.panel-hidden {
			height: auto;
			min-height: 100svh;
			grid-template-areas:
				'identity'
				'scene'
				'canvas'
				'uniforms'
				'status';
			grid-template-columns: minmax(0, 1fr);
			grid-template-rows: auto auto minmax(24rem, 60svh) auto 2rem;
			overflow: visible;
		}

		.identity-bar,
		.scene-controls,
		.uniform-region {
			position: static;
			width: auto;
			height: auto;
			max-width: none;
			border-radius: 0;
			box-shadow: none;
		}

		.identity-bar {
			grid-area: identity;
			min-height: 4.25rem;
			border-bottom: 1px solid var(--border);
		}

		.scene-controls {
			grid-area: scene;
			align-items: stretch;
			flex-direction: column;
			border-bottom: 1px solid var(--border);
		}

		.scene-options {
			overflow: visible;
		}

		.uniform-region {
			grid-area: uniforms;
			max-height: 42svh;
			border-top: 1px solid var(--border);
		}

		.panel-reveal {
			position: static;
			grid-area: uniforms;
			justify-self: end;
			margin: 0.75rem;
		}

		.viewport-hint,
		.panel-hidden .viewport-hint {
			right: 0.75rem;
		}

		.status-path {
			display: none;
		}
	}

	@media (max-width: 520px) {
		.gallery-link span:last-child,
		.shader-identity code,
		.harness-badge,
		.status-strip > span:not(.render-status) {
			display: none;
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.gallery-link,
		.panel-reveal,
		.scene-options button,
		.viewport-hint {
			transition: none;
		}
	}
</style>
