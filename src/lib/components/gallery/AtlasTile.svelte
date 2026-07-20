<script lang="ts">
	import Heart from 'phosphor-svelte/lib/Heart';
	import type { ShaderEntry } from '$lib/shaders/types';
	import type { GalleryState } from '$lib/gallery/gallery-state.svelte';
	import type { PreviewRegistry } from '$lib/gallery/preview-registry';
	import { cn } from '$lib/utils';

	let {
		entry,
		gallery,
		registry,
		featured = false
	}: {
		entry: ShaderEntry;
		gallery: GalleryState;
		registry: PreviewRegistry;
		featured?: boolean;
	} = $props();

	const selected = $derived(gallery.selected?.slug === entry.slug);
	const favorite = $derived(gallery.isFavorite(entry.slug));
</script>

<!--
	The preview area is a transparent window onto the shared preview canvas
	behind the grid (D7). The 8px viewport-black border forms the tile's
	rounded shell while keeping the scissored render rect square inside it.
-->
<div class={cn('group relative flex h-full flex-col overflow-hidden rounded-tile', featured && 'text-[1rem]')}>
	<div class="relative min-h-0 flex-1 rounded-t-tile border-8 border-b-0 border-viewport">
		<div class="absolute inset-0" {@attach (el) => registry.register(entry.slug, el)}></div>
	</div>

	<div class="flex items-center gap-2 bg-viewport px-2.5 pb-2 pt-1.5">
		<span
			class={cn(
				'min-w-0 truncate text-[0.8125rem] font-[550]',
				featured && 'text-[0.9375rem]',
				selected ? 'text-foreground' : 'text-muted-foreground'
			)}
		>
			{entry.meta.name}
		</span>
		<span class="ms-auto shrink-0 font-mono text-[0.6875rem] text-ink-subtle">
			{entry.meta.harness}{entry.meta.scene ? ' · scene' : ''}
		</span>
	</div>

	<!-- Select on click, open in the studio on double-click. -->
	<button
		type="button"
		class="absolute inset-0 rounded-tile focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
		aria-label={`${entry.meta.name} — ${entry.meta.harness} harness`}
		aria-current={selected ? 'true' : undefined}
		onclick={() => gallery.select(entry.slug)}
		ondblclick={() => gallery.open(entry)}
	></button>

	<!-- Quiet Deep Berry selection edge (Signal Red stays reserved for focus). -->
	{#if selected}
		<div class="pointer-events-none absolute inset-0 rounded-tile ring-1 ring-inset ring-selected"></div>
	{/if}

	<button
		type="button"
		class={cn(
			'absolute end-2.5 top-2.5 z-10 flex size-7 items-center justify-center rounded-lg bg-viewport/70 transition-colors duration-150 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
			favorite
				? 'text-primary'
				: 'text-muted-foreground opacity-0 focus-visible:opacity-100 group-hover:opacity-100'
		)}
		aria-label={favorite ? `Remove ${entry.meta.name} from favorites` : `Add ${entry.meta.name} to favorites`}
		aria-pressed={favorite}
		onclick={() => gallery.toggleFavorite(entry.slug)}
	>
		<Heart size={15} weight={favorite ? 'fill' : 'regular'} />
	</button>
</div>
