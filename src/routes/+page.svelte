<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import DiscoveryRail from '$lib/components/gallery/DiscoveryRail.svelte';
	import CommandBand from '$lib/components/gallery/CommandBand.svelte';
	import AtlasGrid from '$lib/components/gallery/AtlasGrid.svelte';
	import DetailStrip from '$lib/components/gallery/DetailStrip.svelte';
	import CommandSearch from '$lib/components/gallery/CommandSearch.svelte';
	import PreviewCanvas from '$lib/gallery/PreviewCanvas.svelte';
	import { GalleryState } from '$lib/gallery/gallery-state.svelte';
	import { PreviewRegistry } from '$lib/gallery/preview-registry';

	const gallery = new GalleryState();
	const registry = new PreviewRegistry();

	function inEditableTarget(event: KeyboardEvent): boolean {
		const el = event.target as HTMLElement | null;
		return (
			el !== null &&
			(el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable)
		);
	}

	function onkeydown(event: KeyboardEvent) {
		if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
			event.preventDefault();
			gallery.paletteOpen = !gallery.paletteOpen;
			return;
		}
		if (gallery.paletteOpen || inEditableTarget(event)) return;
		switch (event.key) {
			case '/':
				event.preventDefault();
				document.getElementById('gallery-search')?.focus();
				break;
			case 'ArrowRight':
			case 'ArrowDown':
				event.preventDefault();
				gallery.moveSelection(1);
				break;
			case 'ArrowLeft':
			case 'ArrowUp':
				event.preventDefault();
				gallery.moveSelection(-1);
				break;
			case 'Enter':
				if (gallery.selected) {
					event.preventDefault();
					gallery.open(gallery.selected);
				}
				break;
		}
	}
</script>

<svelte:head>
	<title>shader-studio — gallery</title>
</svelte:head>

<svelte:window {onkeydown} />

<div class="flex h-svh">
	<DiscoveryRail {gallery} />

	<main class="relative flex min-w-0 flex-1 flex-col">
		{#if gallery.entries.length > 0}
			<PreviewCanvas {registry} />
		{/if}

		<!-- No z-index: descendants that must overlay the z-20 canvas use z-30
		     in the root stacking context; everything else shows through the
		     canvas's transparent pixels. -->
		<div class="relative flex min-h-0 flex-1 flex-col">
			<CommandBand {gallery} />

			<div class="relative min-h-0 flex-1">
				{#if gallery.entries.length === 0}
					<div class="flex h-full flex-col items-center justify-center gap-4 p-8 text-center">
						<h1 class="text-[1.5rem] font-[650] tracking-[-0.02em]">Add your first shader</h1>
						<p class="max-w-[44ch] text-[0.9375rem] leading-relaxed text-muted-foreground">
							A shader entry is a folder — drop one under <code class="font-mono">shaders/</code> and
							it appears here, live. No registration step.
						</p>
						<pre
							class="rounded-panel bg-surface px-5 py-4 text-start font-mono text-[0.8125rem] leading-relaxed text-muted-foreground">shaders/my-effect/
  fragment.glsl
  meta.json</pre>
					</div>
				{:else if gallery.visible.length === 0}
					<div class="flex h-full flex-col items-center justify-center gap-3 p-8 text-center">
						<h1 class="text-[1.25rem] font-[650] tracking-[-0.015em]">No shaders match</h1>
						<p class="text-[0.9375rem] text-muted-foreground">
							Nothing in the collection matches the current search and filters.
						</p>
						<Button variant="secondary" class="mt-1 h-9" onclick={() => gallery.clearFilters()}>
							Clear filters
						</Button>
					</div>
				{:else}
					<div class="absolute inset-0 overflow-y-auto">
						<AtlasGrid {gallery} {registry} />
					</div>
				{/if}
			</div>

			<DetailStrip {gallery} {registry} />
		</div>
	</main>
</div>

<CommandSearch {gallery} />
