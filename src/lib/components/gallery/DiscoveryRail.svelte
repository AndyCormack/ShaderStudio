<script lang="ts">
	import Hexagon from 'phosphor-svelte/lib/Hexagon';
	import SquaresFour from 'phosphor-svelte/lib/SquaresFour';
	import Star from 'phosphor-svelte/lib/Star';
	import ClockCounterClockwise from 'phosphor-svelte/lib/ClockCounterClockwise';
	import Stack from 'phosphor-svelte/lib/Stack';
	import FrameCorners from 'phosphor-svelte/lib/FrameCorners';
	import Cube from 'phosphor-svelte/lib/Cube';
	import Tag from 'phosphor-svelte/lib/Tag';
	import type { GalleryState, HarnessFilter, RailSection } from '$lib/gallery/gallery-state.svelte';
	import { cn } from '$lib/utils';

	let { gallery }: { gallery: GalleryState } = $props();

	const sections: { id: RailSection; label: string; icon: typeof SquaresFour }[] = [
		{ id: 'gallery', label: 'Gallery', icon: SquaresFour },
		{ id: 'favorites', label: 'Favorites', icon: Star },
		{ id: 'recent', label: 'Recent', icon: ClockCounterClockwise }
	];

	const harnesses: { id: HarnessFilter; label: string; icon: typeof Stack }[] = [
		{ id: 'all', label: 'All shaders', icon: Stack },
		{ id: 'quad', label: 'Quad', icon: FrameCorners },
		{ id: 'mesh', label: 'Mesh', icon: Cube }
	];

	const sectionCounts = $derived({
		gallery: gallery.entries.length,
		favorites: gallery.entries.filter((e) => gallery.favorites.includes(e.slug)).length,
		recent: gallery.entries.filter((e) => gallery.recents.includes(e.slug)).length
	});

	const harnessCounts = $derived({
		all: gallery.entries.length,
		quad: gallery.entries.filter((e) => e.meta.harness === 'quad').length,
		mesh: gallery.entries.filter((e) => e.meta.harness === 'mesh').length
	});

	function itemClass(active: boolean): string {
		return cn(
			'flex h-10 w-full items-center gap-2.5 rounded-lg px-3 text-[0.8125rem] font-[550] transition-colors duration-150',
			active
				? 'bg-selected text-foreground'
				: 'text-muted-foreground hover:bg-surface-raised/60 hover:text-foreground'
		);
	}
</script>

<nav
	class="hidden w-64 shrink-0 flex-col border-r border-border bg-surface md:flex"
	aria-label="Discovery"
>
	<a href="/" class="flex items-center gap-2.5 px-4 pb-5 pt-4">
		<Hexagon size={28} weight="duotone" class="shrink-0 text-signature" />
		<span class="flex flex-col">
			<span class="text-[0.9375rem] font-semibold leading-tight tracking-tight">shader-studio</span>
			<span class="text-[0.5625rem] font-[550] tracking-[0.22em] text-muted-foreground">
				ELECTRIC WORKBENCH
			</span>
		</span>
	</a>

	<div class="flex flex-col gap-0.5 px-2.5">
		{#each sections as { id, label, icon: Icon } (id)}
			{@const active = gallery.section === id && gallery.tag === null}
			<button
				type="button"
				class={itemClass(active)}
				aria-current={active ? 'true' : undefined}
				onclick={() => {
					gallery.section = id;
					gallery.tag = null;
				}}
			>
				<Icon size={17} weight={active ? 'fill' : 'regular'} />
				<span>{label}</span>
				<span class="ms-auto text-xs tabular-nums text-muted-foreground">{sectionCounts[id]}</span>
			</button>
		{/each}
	</div>

	<div class="mt-5 flex flex-col gap-0.5 px-2.5" role="group" aria-label="Filter by harness">
		{#each harnesses as { id, label, icon: Icon } (id)}
			{@const active = gallery.harness === id && id !== 'all'}
			<button
				type="button"
				class={itemClass(active)}
				aria-pressed={active}
				onclick={() => (gallery.harness = id)}
			>
				<Icon size={17} weight={active ? 'fill' : 'regular'} />
				<span>{label}</span>
				<span class="ms-auto text-xs tabular-nums text-muted-foreground">{harnessCounts[id]}</span>
			</button>
		{/each}
	</div>

	{#if gallery.tagCounts.length > 0}
		<div class="mt-5 flex min-h-0 flex-1 flex-col">
			<p class="px-5 pb-1.5 text-xs font-[550] text-muted-foreground">Tags</p>
			<div class="flex flex-col gap-0.5 overflow-y-auto px-2.5">
				{#each gallery.tagCounts as [tag, count] (tag)}
					<button
						type="button"
						class={itemClass(gallery.tag === tag)}
						aria-current={gallery.tag === tag ? 'true' : undefined}
						onclick={() => {
							gallery.tag = gallery.tag === tag ? null : tag;
							gallery.section = 'gallery';
						}}
					>
						<Tag size={17} weight={gallery.tag === tag ? 'fill' : 'regular'} />
						<span class="truncate font-mono text-[0.8125rem]">{tag}</span>
						<span class="ms-auto text-xs tabular-nums text-muted-foreground">{count}</span>
					</button>
				{/each}
			</div>
		</div>
	{/if}
</nav>
