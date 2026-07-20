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
			'flex h-11 w-full items-center gap-3 rounded-lg border px-3.5 text-sm font-[500] transition-colors duration-150',
			active
				? 'border-primary/25 bg-selected font-[550] text-foreground'
				: 'border-transparent text-muted-foreground hover:bg-surface-raised/60 hover:text-foreground'
		);
	}
</script>

<nav
	class="hidden w-72 shrink-0 flex-col border-r border-border bg-surface md:flex"
	aria-label="Discovery"
>
	<!-- Brand block sits on the darker frame color with its own divider,
	     framing the top row with the command band. -->
	<a href="/" class="flex h-[4.5rem] shrink-0 items-center gap-3 border-b border-border bg-background px-5">
		<Hexagon size={34} weight="duotone" class="shrink-0 text-signature" />
		<span class="flex flex-col gap-0.5">
			<span class="text-[1.0625rem] font-semibold leading-tight tracking-tight">shader-studio</span>
			<span class="text-[0.5625rem] font-[550] tracking-[0.22em] text-muted-foreground">
				ELECTRIC WORKBENCH
			</span>
		</span>
	</a>

	<div class="mt-3 flex flex-col gap-1 px-3">
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
				<Icon size={18} weight={active ? 'fill' : 'regular'} />
				<span>{label}</span>
				<span class="ms-auto text-xs tabular-nums text-muted-foreground">{sectionCounts[id]}</span>
			</button>
		{/each}
	</div>

	<div class="mx-5 my-3.5 border-t border-border"></div>

	<div class="flex flex-col gap-1 px-3" role="group" aria-label="Filter by harness">
		{#each harnesses as { id, label, icon: Icon } (id)}
			{@const active = gallery.harness === id && id !== 'all'}
			<button
				type="button"
				class={itemClass(active)}
				aria-pressed={active}
				onclick={() => (gallery.harness = id)}
			>
				<Icon size={18} weight={active ? 'fill' : 'regular'} />
				<span>{label}</span>
				<span class="ms-auto text-xs tabular-nums text-muted-foreground">{harnessCounts[id]}</span>
			</button>
		{/each}
	</div>

	{#if gallery.tagCounts.length > 0}
		<div class="flex min-h-0 flex-1 flex-col">
			<div class="mx-5 my-3.5 border-t border-border"></div>
			<p class="px-6 pb-2 text-xs font-[550] text-muted-foreground">Tags</p>
			<div class="flex flex-col gap-1 overflow-y-auto px-3">
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
						<Tag size={18} weight={gallery.tag === tag ? 'fill' : 'regular'} />
						<span class="truncate font-mono text-[0.8125rem]">{tag}</span>
						<span class="ms-auto text-xs tabular-nums text-muted-foreground">{count}</span>
					</button>
				{/each}
			</div>
		</div>
	{/if}
</nav>
