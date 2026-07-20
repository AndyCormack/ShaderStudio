<script lang="ts">
	import Star from 'phosphor-svelte/lib/Star';
	import DotsThree from 'phosphor-svelte/lib/DotsThree';
	import ArrowUpRight from 'phosphor-svelte/lib/ArrowUpRight';
	import LinkSimple from 'phosphor-svelte/lib/LinkSimple';
	import { Badge } from '$lib/components/ui/badge';
	import * as DropdownMenu from '$lib/components/ui/dropdown-menu';
	import { formatAgo, formatSize } from '$lib/gallery/format';
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
	const fragmentPath = $derived(`shaders/${entry.slug}/fragment.glsl`);
</script>

<!--
	Card anatomy per the Preview Atlas mockup: the live preview (a transparent
	window onto the shared canvas, D7) fills the whole card; metadata overlays
	its lower edge on a vignette that fades the render into the card's plum
	surface so text stays legible over any shader. The corner mask paints over
	the square scissored corners so the rounded card edge stays clean.
-->
<div
	class={cn(
		'group relative flex h-full flex-col overflow-hidden rounded-tile border transition-[border-color,box-shadow] duration-150',
		selected
			? 'border-primary/60 shadow-[0_0_18px_-6px_oklch(0.55_0.21_18/0.28)]'
			: 'border-border'
	)}
>
	<div class="absolute inset-0" {@attach (el) => registry.register(entry.slug, entry.slug, el)}></div>

	<!-- Corner mask + an edge feather that dissolves the render into the card
	     surface on every side (the scissored canvas can't be CSS-masked, so
	     the blend is painted over it); selection adds an inset Signal glow. -->
	<div
		class={cn(
			'pointer-events-none absolute inset-0 z-30 rounded-[7px]',
			selected
				? 'shadow-[0_0_0_32px_var(--color-background),inset_0_0_30px_2px_oklch(0.55_0.21_18/0.3)]'
				: 'shadow-[0_0_0_32px_var(--color-background)]'
		)}
		style="background:
			linear-gradient(to right, var(--color-surface), transparent 34%),
			linear-gradient(to left, var(--color-surface), transparent 34%),
			linear-gradient(to bottom, var(--color-surface), transparent 40%),
			linear-gradient(to top, var(--color-surface), transparent 52%),
			radial-gradient(ellipse 78% 78% at 50% 44%, transparent 38%, color-mix(in oklab, var(--color-surface) 78%, transparent) 82%, var(--color-surface) 100%);"
	></div>

	<!-- Metadata sits on solid surface; a fixed-height, even fade above it
	     lifts the block off the render and completes before the title line,
	     so no gradient runs behind the text. -->
	<div class="absolute inset-x-0 bottom-0 z-30 flex flex-col">
		<div class="h-12 bg-gradient-to-t from-surface to-transparent"></div>
		<div class="flex flex-col gap-1.5 rounded-b-[7px] bg-surface px-3.5 pb-3">
			<div class="flex items-center gap-2">
			<span
				class={cn(
					'min-w-0 truncate font-[650] text-foreground',
					featured ? 'text-[1.25rem] tracking-[-0.015em]' : 'text-[1rem]'
				)}
			>
				{entry.meta.name}
			</span>
			<Badge variant="outline" class="shrink-0 text-[0.6875rem] capitalize text-muted-foreground">
				{entry.meta.harness}
			</Badge>
		</div>
		<span class="truncate font-mono text-xs text-muted-foreground">{fragmentPath}</span>
		{#if entry.meta.tags?.length}
			<div class="flex flex-wrap gap-1">
				{#each entry.meta.tags as tag (tag)}
					<span
						class="rounded-[5px] border border-border/70 bg-surface-raised/60 px-2 py-0.5 text-[0.6875rem] text-muted-foreground"
					>
						{tag}
					</span>
				{/each}
			</div>
		{/if}
			<span class="mt-1 truncate pe-7 text-[0.6875rem] tabular-nums text-muted-foreground">
				{entry.glslVersion} &nbsp;·&nbsp; {formatSize(entry.glslBytes)} &nbsp;·&nbsp; Updated {formatAgo(
					entry.updatedAt
				)}
			</span>
		</div>
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

	<!-- Overflow actions: bottom-right of the meta row, per the mockup. -->
	<DropdownMenu.Root>
		<DropdownMenu.Trigger
			class="absolute bottom-2 end-2 z-30 flex size-6 items-center justify-center rounded-[5px] text-muted-foreground transition-colors duration-150 hover:bg-surface-raised hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring data-open:bg-surface-raised data-open:text-foreground"
			aria-label={`More actions for ${entry.meta.name}`}
		>
			<DotsThree size={18} weight="bold" />
		</DropdownMenu.Trigger>
		<DropdownMenu.Content align="end" class="w-48">
			<DropdownMenu.Item onclick={() => gallery.open(entry)}>
				<ArrowUpRight size={15} aria-hidden="true" />
				Open shader
			</DropdownMenu.Item>
			<DropdownMenu.Item onclick={() => navigator.clipboard.writeText(fragmentPath)}>
				<LinkSimple size={15} aria-hidden="true" />
				Copy path
			</DropdownMenu.Item>
			<DropdownMenu.Separator />
			<DropdownMenu.Item onclick={() => gallery.toggleFavorite(entry.slug)}>
				<Star size={15} aria-hidden="true" />
				{favorite ? 'Remove from favorites' : 'Add to favorites'}
			</DropdownMenu.Item>
		</DropdownMenu.Content>
	</DropdownMenu.Root>
</div>
