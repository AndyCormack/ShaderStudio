<script lang="ts">
	import AtlasTile from './AtlasTile.svelte';
	import type { GalleryState } from '$lib/gallery/gallery-state.svelte';
	import type { PreviewRegistry } from '$lib/gallery/preview-registry';

	let { gallery, registry }: { gallery: GalleryState; registry: PreviewRegistry } = $props();

	// Preview Atlas sizing (D12): one featured cell, medium supporting
	// previews, small scan-density tiles — all on the shared 12-column grid.
	// Fine 7.5rem rows let heights step like the mockup: featured ≈ 3 rows,
	// supporting tiles ≈ 2.
	function sizeClass(index: number): string {
		if (index === 0) return 'col-span-2 row-span-3 md:col-span-6 xl:col-span-6';
		if (index <= 4) return 'col-span-1 row-span-2 md:col-span-3 xl:col-span-3';
		return 'col-span-1 row-span-2 md:col-span-2 xl:col-span-2';
	}
</script>

<div
	class="grid auto-rows-[7.5rem] grid-cols-2 gap-3.5 p-4 md:grid-cols-6 xl:grid-cols-12"
	role="list"
	aria-label="Shader previews"
>
	{#each gallery.visible as entry, index (entry.slug)}
		<div role="listitem" class={sizeClass(index)}>
			<AtlasTile {entry} {gallery} {registry} featured={index === 0} />
		</div>
	{/each}
</div>
