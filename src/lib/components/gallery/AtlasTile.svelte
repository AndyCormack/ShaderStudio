<script lang="ts">
	import Star from 'phosphor-svelte/lib/Star';
	import { Badge } from '$lib/components/ui/badge';
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

	const metaParts = $derived(
		[
			entry.meta.harness === 'mesh' ? (entry.meta.primitive ?? 'sphere') : undefined,
			entry.meta.scene ? 'custom scene' : undefined,
			entry.vertex ? 'custom vertex' : undefined,
			entry.meta.uniforms?.length
				? `${entry.meta.uniforms.length} uniform${entry.meta.uniforms.length === 1 ? '' : 's'}`
				: undefined
		].filter(Boolean) as string[]
	);
</script>

<!--
	Card anatomy per the Preview Atlas mockup: live preview on top (a
	transparent window onto the shared canvas, D7), metadata block below on
	the card surface. The corner mask paints over the square scissored
	corners so the card's rounded top stays clean.
-->
<div
	class={cn(
		'group relative flex h-full flex-col overflow-hidden rounded-tile border transition-colors duration-150',
		selected ? 'border-primary/60' : 'border-border'
	)}
>
	<div
		class="relative min-h-0 flex-1 overflow-hidden"
		{@attach (el) => registry.register(entry.slug, entry.slug, el)}
	>
		<div
			class="pointer-events-none absolute inset-0 z-30 rounded-t-[7px] shadow-[0_0_0_32px_var(--color-background)]"
		></div>
	</div>

	<div class="flex flex-col gap-1 bg-surface px-3 pb-2.5 pt-2">
		<div class="flex items-center gap-2">
			<span
				class={cn(
					'min-w-0 truncate font-[600] text-foreground',
					featured ? 'text-[1.0625rem]' : 'text-[0.9375rem]'
				)}
			>
				{entry.meta.name}
			</span>
			<Badge variant="outline" class="shrink-0 text-[0.6875rem] capitalize text-muted-foreground">
				{entry.meta.harness}
			</Badge>
		</div>
		<span class="truncate font-mono text-xs text-muted-foreground">shaders/{entry.slug}/</span>
		{#if entry.meta.tags?.length}
			<div class="flex flex-wrap gap-1">
				{#each entry.meta.tags as tag (tag)}
					<span
						class="rounded-[4px] bg-surface-raised px-1.5 py-0.5 text-[0.6875rem] text-muted-foreground"
					>
						{tag}
					</span>
				{/each}
			</div>
		{/if}
		{#if metaParts.length}
			<span class="truncate text-[0.6875rem] text-muted-foreground">{metaParts.join(' · ')}</span>
		{/if}
	</div>

	<!-- Select on click, open in the studio on double-click. -->
	<button
		type="button"
		class="absolute inset-0 z-30 rounded-tile focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
		aria-label={`${entry.meta.name} — ${entry.meta.harness} harness`}
		aria-current={selected ? 'true' : undefined}
		onclick={() => gallery.select(entry.slug)}
		ondblclick={() => gallery.open(entry)}
	></button>

	<!-- Favorite star: always visible, top-left, Favorite Rose when active. -->
	<button
		type="button"
		class={cn(
			'absolute start-2 top-2 z-30 flex size-7 items-center justify-center rounded-lg drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)] transition-colors duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
			favorite ? 'text-favorite' : 'text-muted-foreground hover:text-foreground'
		)}
		aria-label={favorite
			? `Remove ${entry.meta.name} from favorites`
			: `Add ${entry.meta.name} to favorites`}
		aria-pressed={favorite}
		onclick={() => gallery.toggleFavorite(entry.slug)}
	>
		<Star size={16} weight={favorite ? 'fill' : 'regular'} />
	</button>
</div>
